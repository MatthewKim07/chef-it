const router = require('express').Router();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { createPublicKey } = require('crypto');
const { OAuth2Client } = require('google-auth-library');
const db = require('../db');
const requireAuth = require('../middleware/auth');

const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

function signAppToken(user) {
  return jwt.sign({ id: user.id, email: user.email }, process.env.JWT_SECRET, { expiresIn: '24h' });
}

router.post('/register', async (req, res) => {
  const { email, password, display_name } = req.body;
  if (!email || !password) {
    return res.status(400).json({ error: 'email and password required' });
  }

  try {
    const password_hash = await bcrypt.hash(password, 10);
    const { rows } = await db.query(
      'INSERT INTO users (email, password_hash, display_name) VALUES ($1, $2, $3) RETURNING id, email, display_name',
      [email, password_hash, display_name || null]
    );
    const user = rows[0];
    const token = signAppToken(user);
    res.status(201).json({ token, user });
  } catch (err) {
    if (err.code === '23505') {
      return res.status(409).json({ error: 'Email already registered' });
    }
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

router.post('/login', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ error: 'email and password required' });
  }

  try {
    const { rows } = await db.query('SELECT * FROM users WHERE email = $1', [email]);
    const user = rows[0];
    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const match = await bcrypt.compare(password, user.password_hash);
    if (!match) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const token = signAppToken(user);
    const { password_hash, ...safeUser } = user;
    res.json({ token, user: safeUser });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// MARK: - Social Login

async function verifyAppleToken(identityToken) {
  const decoded = jwt.decode(identityToken, { complete: true });
  if (!decoded) throw new Error('Invalid Apple identity token');

  const kid = decoded.header.kid;
  const res = await fetch('https://appleid.apple.com/auth/keys');
  const { keys } = await res.json();
  const jwk = keys.find(k => k.kid === kid);
  if (!jwk) throw new Error('Apple signing key not found');

  const pem = createPublicKey({ key: jwk, format: 'jwk' }).export({ type: 'spki', format: 'pem' });

  return jwt.verify(identityToken, pem, {
    algorithms: ['RS256'],
    audience: process.env.APPLE_CLIENT_ID,
    issuer: 'https://appleid.apple.com',
    clockTolerance: 60
  });
}

async function findOrCreateOAuthUser(email, provider, providerId, displayName) {
  // Try to find existing user by email
  let { rows } = await db.query('SELECT * FROM users WHERE email = $1', [email]);
  if (rows.length > 0) {
    const user = rows[0];
    const { password_hash, ...safeUser } = user;
    return safeUser;
  }

  // Create new OAuth user
  const { rows: inserted } = await db.query(
    'INSERT INTO users (email, display_name, auth_provider, provider_id) VALUES ($1, $2, $3, $4) RETURNING id, email, display_name, auth_provider, provider_id, created_at',
    [email, displayName || null, provider, providerId]
  );
  return inserted[0];
}

router.post('/google', async (req, res) => {
  const { id_token } = req.body;
  if (!id_token) {
    return res.status(400).json({ error: 'id_token required' });
  }

  try {
    const ticket = await googleClient.verifyIdToken({
      idToken: id_token,
      audience: process.env.GOOGLE_CLIENT_ID
    });
    const payload = ticket.getPayload();
    if (!payload) {
      return res.status(401).json({ error: 'Invalid Google token' });
    }

    const email = payload.email;
    const displayName = payload.name || payload.given_name;
    const providerId = payload.sub;

    const user = await findOrCreateOAuthUser(email, 'google', providerId, displayName);
    const token = signAppToken(user);
    res.json({ token, user });
  } catch (err) {
    console.error('Google auth error:', err.message);
    res.status(401).json({ error: 'Google sign-in failed' });
  }
});

router.post('/apple', async (req, res) => {
  const { identity_token, display_name } = req.body;
  if (!identity_token) {
    return res.status(400).json({ error: 'identity_token required' });
  }

  try {
    const payload = await verifyAppleToken(identity_token);
    const email = payload.email;
    const providerId = payload.sub;

    if (!email) {
      return res.status(400).json({ error: 'Apple token did not contain email' });
    }

    const user = await findOrCreateOAuthUser(email, 'apple', providerId, display_name);
    const token = signAppToken(user);
    res.json({ token, user });
  } catch (err) {
    console.error('Apple auth error:', err.message);
    res.status(401).json({ error: 'Apple sign-in failed' });
  }
});

router.post('/change-password', requireAuth, async (req, res) => {
  const { current_password, new_password } = req.body;
  if (!current_password || !new_password) {
    return res.status(400).json({ error: 'current_password and new_password required' });
  }
  if (new_password.length < 6) {
    return res.status(400).json({ error: 'New password must be at least 6 characters' });
  }

  try {
    const { rows } = await db.query('SELECT password_hash FROM users WHERE id = $1', [req.user.id]);
    const user = rows[0];
    if (!user) return res.status(404).json({ error: 'User not found' });
    if (!user.password_hash) {
      return res.status(400).json({ error: 'Password change is not available for social login accounts' });
    }

    const match = await bcrypt.compare(current_password, user.password_hash);
    if (!match) return res.status(401).json({ error: 'Current password is incorrect' });

    const new_hash = await bcrypt.hash(new_password, 10);
    await db.query('UPDATE users SET password_hash = $1 WHERE id = $2', [new_hash, req.user.id]);
    res.json({ ok: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

router.post('/change-email', requireAuth, async (req, res) => {
  const { password, new_email } = req.body;
  if (!password || !new_email) {
    return res.status(400).json({ error: 'password and new_email required' });
  }

  try {
    const { rows } = await db.query('SELECT * FROM users WHERE id = $1', [req.user.id]);
    const user = rows[0];
    if (!user) return res.status(404).json({ error: 'User not found' });
    if (!user.password_hash) {
      return res.status(400).json({ error: 'Email change is not available for social login accounts' });
    }

    const match = await bcrypt.compare(password, user.password_hash);
    if (!match) return res.status(401).json({ error: 'Password is incorrect' });

    const updated = await db.query(
      'UPDATE users SET email = $1 WHERE id = $2 RETURNING id, email, display_name',
      [new_email, req.user.id]
    );
    const newUser = updated.rows[0];
    const token = signAppToken(newUser);
    res.json({ token, user: newUser });
  } catch (err) {
    if (err.code === '23505') {
      return res.status(409).json({ error: 'Email already registered' });
    }
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

router.delete('/account', requireAuth, async (req, res) => {
  const { password } = req.body;

  const client = await db.pool.connect();
  try {
    const { rows } = await client.query('SELECT password_hash FROM users WHERE id = $1', [req.user.id]);
    const user = rows[0];
    if (!user) return res.status(404).json({ error: 'User not found' });

    if (user.password_hash) {
      if (!password) {
        return res.status(400).json({ error: 'password required' });
      }
      const match = await bcrypt.compare(password, user.password_hash);
      if (!match) return res.status(401).json({ error: 'Password is incorrect' });
    }

    await client.query('BEGIN');
    await client.query('DELETE FROM notifications WHERE user_id = $1 OR actor_id = $1', [req.user.id]);
    await client.query('DELETE FROM notifications WHERE post_id IN (SELECT id FROM posts WHERE user_id = $1)', [req.user.id]);
    await client.query('DELETE FROM comments WHERE user_id = $1', [req.user.id]);
    await client.query('DELETE FROM comments WHERE post_id IN (SELECT id FROM posts WHERE user_id = $1)', [req.user.id]);
    await client.query('DELETE FROM post_likes WHERE user_id = $1', [req.user.id]);
    await client.query('DELETE FROM post_likes WHERE post_id IN (SELECT id FROM posts WHERE user_id = $1)', [req.user.id]);
    await client.query('DELETE FROM follows WHERE follower_id = $1 OR following_id = $1', [req.user.id]);
    await client.query('DELETE FROM reviews WHERE user_id = $1', [req.user.id]);
    await client.query('DELETE FROM posts WHERE user_id = $1', [req.user.id]);
    await client.query('DELETE FROM users WHERE id = $1', [req.user.id]);
    await client.query('COMMIT');
    res.json({ ok: true });
  } catch (err) {
    await client.query('ROLLBACK').catch(() => {});
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  } finally {
    client.release();
  }
});

module.exports = router;
