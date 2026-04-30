const router = require('express').Router();
const db = require('../db');
const requireAuth = require('../middleware/auth');
const { upload, uploadBuffer } = require('../middleware/upload');

// GET /api/users/:id — public, no sensitive fields
router.get('/:id', async (req, res) => {
  try {
    const { rows } = await db.query(
      'SELECT id, display_name, bio, avatar_url, created_at FROM users WHERE id = $1',
      [req.params.id]
    );
    if (!rows[0]) return res.status(404).json({ error: 'User not found' });
    res.json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// PUT /api/users/:id — protected, own profile only
router.put('/:id', requireAuth, async (req, res) => {
  if (req.user.id !== parseInt(req.params.id, 10)) {
    return res.status(403).json({ error: 'Forbidden' });
  }

  const { display_name, bio } = req.body;
  try {
    const { rows } = await db.query(
      `UPDATE users
         SET display_name = COALESCE($1, display_name),
             bio          = COALESCE($2, bio)
       WHERE id = $3
       RETURNING id, display_name, bio, avatar_url, created_at`,
      [display_name || null, bio || null, req.params.id]
    );
    res.json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// POST /api/users/:id/avatar — protected, own profile only
router.post('/:id/avatar', requireAuth, upload.single('avatar'), async (req, res) => {
  if (req.user.id !== parseInt(req.params.id, 10)) {
    return res.status(403).json({ error: 'Forbidden' });
  }
  if (!req.file) {
    return res.status(400).json({ error: 'No image file provided' });
  }

  try {
    const result = await uploadBuffer(req.file.buffer, 'chefit/avatars');
    const { rows } = await db.query(
      `UPDATE users SET avatar_url = $1 WHERE id = $2
       RETURNING id, display_name, bio, avatar_url, created_at`,
      [result.secure_url, req.params.id]
    );
    res.json({ avatar_url: rows[0].avatar_url });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
