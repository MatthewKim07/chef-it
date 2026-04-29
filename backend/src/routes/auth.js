const router = require('express').Router();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const db = require('../db');

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
    const token = jwt.sign({ id: user.id, email: user.email }, process.env.JWT_SECRET, { expiresIn: '24h' });
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

    const token = jwt.sign({ id: user.id, email: user.email }, process.env.JWT_SECRET, { expiresIn: '24h' });
    const { password_hash, ...safeUser } = user;
    res.json({ token, user: safeUser });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
