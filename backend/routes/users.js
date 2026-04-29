const router = require('express').Router();
const db = require('../db');
const requireAuth = require('../middleware/auth');

router.get('/:id', async (req, res) => {
  try {
    const { rows } = await db.query(
      'SELECT id, display_name, bio, avatar_url, email, created_at FROM users WHERE id = $1',
      [req.params.id]
    );
    if (!rows[0]) return res.status(404).json({ error: 'User not found' });
    res.json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

router.put('/:id', requireAuth, async (req, res) => {
  if (req.user.id !== parseInt(req.params.id, 10)) {
    return res.status(403).json({ error: 'Forbidden' });
  }

  const { display_name, bio, avatar_url } = req.body;
  try {
    const { rows } = await db.query(
      `UPDATE users
         SET display_name = COALESCE($1, display_name),
             bio          = COALESCE($2, bio),
             avatar_url   = COALESCE($3, avatar_url)
       WHERE id = $4
       RETURNING id, display_name, bio, avatar_url, email, created_at`,
      [display_name || null, bio || null, avatar_url || null, req.params.id]
    );
    res.json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
