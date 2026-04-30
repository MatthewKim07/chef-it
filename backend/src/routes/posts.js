const router = require('express').Router();
const db = require('../db');
const requireAuth = require('../middleware/auth');
const { upload, uploadBuffer } = require('../middleware/upload');

const POST_SELECT = `
  SELECT p.id, p.recipe_id, p.caption, p.image_url, p.created_at,
         u.id AS user_id, u.display_name, u.avatar_url
    FROM posts p
    JOIN users u ON u.id = p.user_id`;

// GET /api/posts  (optional ?user_id= filter)
router.get('/', async (req, res) => {
  const offset = parseInt(req.query.offset, 10) || 0;
  const userId = req.query.user_id ? parseInt(req.query.user_id, 10) : null;

  try {
    let query, params;
    if (userId) {
      query = `${POST_SELECT} WHERE p.user_id = $1 ORDER BY p.created_at DESC LIMIT 50 OFFSET $2`;
      params = [userId, offset];
    } else {
      query = `${POST_SELECT} ORDER BY p.created_at DESC LIMIT 20 OFFSET $1`;
      params = [offset];
    }
    const { rows } = await db.query(query, params);
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /api/posts/:id
router.get('/:id', async (req, res) => {
  try {
    const { rows } = await db.query(
      `${POST_SELECT} WHERE p.id = $1`,
      [req.params.id]
    );
    if (!rows[0]) return res.status(404).json({ error: 'Post not found' });
    res.json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// POST /api/posts  (recipe_id optional)
router.post('/', requireAuth, upload.single('image'), async (req, res) => {
  const { recipe_id, caption } = req.body;

  try {
    let image_url = null;
    if (req.file) {
      const result = await uploadBuffer(req.file.buffer, 'chefit/posts');
      image_url = result.secure_url;
    }

    const { rows } = await db.query(
      `INSERT INTO posts (user_id, recipe_id, caption, image_url)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [req.user.id, recipe_id || null, caption || null, image_url]
    );

    // Return full post with user info
    const { rows: full } = await db.query(
      `${POST_SELECT} WHERE p.id = $1`,
      [rows[0].id]
    );
    res.status(201).json(full[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// DELETE /api/posts/:id
router.delete('/:id', requireAuth, async (req, res) => {
  try {
    const { rows } = await db.query('SELECT user_id FROM posts WHERE id = $1', [req.params.id]);
    if (!rows[0]) return res.status(404).json({ error: 'Post not found' });
    if (rows[0].user_id !== req.user.id) return res.status(403).json({ error: 'Forbidden' });

    await db.query('DELETE FROM posts WHERE id = $1', [req.params.id]);
    res.json({ deleted: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /api/posts/:id/comments
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

// POST /api/posts/:id/comments
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
