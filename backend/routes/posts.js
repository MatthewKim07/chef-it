const router = require('express').Router();
const db = require('../db');
const requireAuth = require('../middleware/auth');
const { upload, uploadBuffer } = require('../config/cloudinary');

// Feed
router.get('/', async (req, res) => {
  const offset = parseInt(req.query.offset, 10) || 0;
  try {
    const { rows } = await db.query(
      `SELECT p.id, p.recipe_id, p.caption, p.image_url, p.created_at,
              u.id AS user_id, u.display_name, u.avatar_url
         FROM posts p
         JOIN users u ON u.id = p.user_id
        ORDER BY p.created_at DESC
        LIMIT 20 OFFSET $1`,
      [offset]
    );
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// Create post
router.post('/', requireAuth, upload.single('image'), async (req, res) => {
  const { recipe_id, caption } = req.body;
  if (!recipe_id) return res.status(400).json({ error: 'recipe_id required' });

  try {
    let image_url = null;
    if (req.file) {
      const result = await uploadBuffer(req.file.buffer);
      image_url = result.secure_url;
    }
    const { rows } = await db.query(
      'INSERT INTO posts (user_id, recipe_id, caption, image_url) VALUES ($1, $2, $3, $4) RETURNING *',
      [req.user.id, recipe_id, caption || null, image_url]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// Get comments
router.get('/:id/comments', async (req, res) => {
  try {
    const { rows } = await db.query(
      `SELECT c.id, c.body, c.created_at,
              u.id AS user_id, u.display_name, u.avatar_url
         FROM comments c
         JOIN users u ON u.id = c.user_id
        WHERE c.post_id = $1
        ORDER BY c.created_at ASC`,
      [req.params.id]
    );
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// Add comment
router.post('/:id/comments', requireAuth, async (req, res) => {
  const { body } = req.body;
  if (!body) return res.status(400).json({ error: 'body required' });

  try {
    const { rows } = await db.query(
      'INSERT INTO comments (user_id, post_id, body) VALUES ($1, $2, $3) RETURNING *',
      [req.user.id, req.params.id, body]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
