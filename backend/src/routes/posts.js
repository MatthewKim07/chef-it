const router = require('express').Router();
const db = require('../db');
const requireAuth = require('../middleware/auth');
const optionalAuth = require('../middleware/optionalAuth');
const { upload, uploadBuffer } = require('../middleware/upload');

// Returns post columns + comment_count + like_count + liked_by_me.
// Pass `viewerId` (or null) as the LAST query param so liked_by_me resolves correctly.
function postSelect(viewerIdParamIndex) {
  return `
  SELECT p.id, p.recipe_id, p.caption, p.image_url, p.created_at,
         u.id AS user_id, u.display_name, u.avatar_url,
         COALESCE(c.cnt, 0)::int AS comment_count,
         COALESCE(l.cnt, 0)::int AS like_count,
         CASE WHEN $${viewerIdParamIndex}::int IS NULL THEN false
              ELSE EXISTS(SELECT 1 FROM post_likes pl WHERE pl.post_id = p.id AND pl.user_id = $${viewerIdParamIndex})
         END AS liked_by_me
    FROM posts p
    JOIN users u ON u.id = p.user_id
    LEFT JOIN (SELECT post_id, COUNT(*)::int AS cnt FROM comments GROUP BY post_id) c ON c.post_id = p.id
    LEFT JOIN (SELECT post_id, COUNT(*)::int AS cnt FROM post_likes GROUP BY post_id) l ON l.post_id = p.id`;
}

const COMMENT_SELECT = `
  SELECT c.id, c.body, c.created_at,
         u.id AS user_id, u.display_name, u.avatar_url
    FROM comments c
    JOIN users u ON u.id = c.user_id`;

// GET /api/posts  (optional ?user_id=, ?limit=, ?offset=)
router.get('/', optionalAuth, async (req, res) => {
  const parsedLimit = parseInt(req.query.limit, 10);
  const parsedOffset = parseInt(req.query.offset, 10);
  const parsedUserId = req.query.user_id ? parseInt(req.query.user_id, 10) : null;

  const limit = Number.isInteger(parsedLimit) && parsedLimit > 0
    ? Math.min(parsedLimit, 100)
    : 20;
  const offset = Number.isInteger(parsedOffset) && parsedOffset >= 0
    ? parsedOffset
    : 0;
  const userId = Number.isInteger(parsedUserId) && parsedUserId > 0
    ? parsedUserId
    : null;
  const viewerId = req.user?.id ?? null;

  try {
    let postsQuery, postsParams, countQuery, countParams;
    if (userId) {
      // params: [authorId, limit, offset, viewerId]
      postsQuery  = `${postSelect(4)}
        WHERE p.user_id = $1
        ORDER BY p.created_at DESC
        LIMIT $2 OFFSET $3`;
      postsParams = [userId, limit, offset, viewerId];
      countQuery  = 'SELECT COUNT(*)::int AS total FROM posts WHERE user_id = $1';
      countParams = [userId];
    } else {
      // params: [limit, offset, viewerId]
      postsQuery  = `${postSelect(3)}
        ORDER BY p.created_at DESC
        LIMIT $1 OFFSET $2`;
      postsParams = [limit, offset, viewerId];
      countQuery  = 'SELECT COUNT(*)::int AS total FROM posts';
      countParams = [];
    }

    const [{ rows }, { rows: countRows }] = await Promise.all([
      db.query(postsQuery, postsParams),
      db.query(countQuery, countParams),
    ]);

    res.json({ posts: rows, total: countRows[0].total });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /api/posts/:id
router.get('/:id', optionalAuth, async (req, res) => {
  const viewerId = req.user?.id ?? null;
  try {
    const { rows } = await db.query(
      `${postSelect(2)}
        WHERE p.id = $1`,
      [req.params.id, viewerId]
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
      `${postSelect(2)} WHERE p.id = $1`,
      [rows[0].id, req.user.id]
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

    await db.query('DELETE FROM notifications WHERE post_id = $1', [req.params.id]);
    await db.query('DELETE FROM comments WHERE post_id = $1', [req.params.id]);
    await db.query('DELETE FROM post_likes WHERE post_id = $1', [req.params.id]);
    await db.query('DELETE FROM posts WHERE id = $1', [req.params.id]);
    res.json({ deleted: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// POST /api/posts/:id/like
router.post('/:id/like', requireAuth, async (req, res) => {
  const postId = parseInt(req.params.id, 10);
  if (!Number.isInteger(postId)) return res.status(400).json({ error: 'Invalid post id' });

  try {
    const { rows: postRows } = await db.query('SELECT id, user_id FROM posts WHERE id = $1', [postId]);
    if (!postRows[0]) return res.status(404).json({ error: 'Post not found' });

    await db.query(
      `INSERT INTO post_likes (user_id, post_id) VALUES ($1, $2)
       ON CONFLICT (user_id, post_id) DO NOTHING`,
      [req.user.id, postId]
    );

    // Notify post owner (skip self-likes).
    if (postRows[0].user_id !== req.user.id) {
      await db.query(
        `INSERT INTO notifications (user_id, actor_id, type, post_id)
         VALUES ($1, $2, 'like', $3)
         ON CONFLICT (user_id, actor_id, post_id) WHERE type = 'like' DO NOTHING`,
        [postRows[0].user_id, req.user.id, postId]
      );
    }

    const { rows } = await db.query(
      'SELECT COUNT(*)::int AS cnt FROM post_likes WHERE post_id = $1',
      [postId]
    );
    res.json({ liked: true, like_count: rows[0].cnt });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// DELETE /api/posts/:id/like
router.delete('/:id/like', requireAuth, async (req, res) => {
  const postId = parseInt(req.params.id, 10);
  if (!Number.isInteger(postId)) return res.status(400).json({ error: 'Invalid post id' });

  try {
    await db.query(
      'DELETE FROM post_likes WHERE user_id = $1 AND post_id = $2',
      [req.user.id, postId]
    );
    // Remove the like notification when unliked.
    await db.query(
      `DELETE FROM notifications
       WHERE actor_id = $1 AND post_id = $2 AND type = 'like'`,
      [req.user.id, postId]
    );
    const { rows } = await db.query(
      'SELECT COUNT(*)::int AS cnt FROM post_likes WHERE post_id = $1',
      [postId]
    );
    res.json({ liked: false, like_count: rows[0].cnt });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /api/posts/:id/comments
router.get('/:id/comments', async (req, res) => {
  try {
    const { rows } = await db.query(
      `${COMMENT_SELECT}
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
    const postId = parseInt(req.params.id, 10);
    const { rows: postRows } = await db.query('SELECT user_id FROM posts WHERE id = $1', [postId]);
    if (!postRows[0]) return res.status(404).json({ error: 'Post not found' });

    const { rows } = await db.query(
      'INSERT INTO comments (user_id, post_id, body) VALUES ($1, $2, $3) RETURNING *',
      [req.user.id, postId, body]
    );

    // Notify post owner (skip self-comments).
    if (postRows[0].user_id !== req.user.id) {
      await db.query(
        `INSERT INTO notifications (user_id, actor_id, type, post_id, comment_id)
         VALUES ($1, $2, 'comment', $3, $4)`,
        [postRows[0].user_id, req.user.id, postId, rows[0].id]
      );
    }

    const { rows: full } = await db.query(
      `${COMMENT_SELECT} WHERE c.id = $1`,
      [rows[0].id]
    );
    res.status(201).json(full[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
