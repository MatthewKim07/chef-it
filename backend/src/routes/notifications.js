const router = require('express').Router();
const db = require('../db');
const requireAuth = require('../middleware/auth');

const NOTIF_SELECT = `
  SELECT n.id, n.type, n.post_id, n.comment_id, n.read_at, n.created_at,
         u.id AS actor_id, u.display_name AS actor_display_name, u.avatar_url AS actor_avatar_url,
         p.image_url AS post_image_url
    FROM notifications n
    JOIN users u  ON u.id = n.actor_id
    LEFT JOIN posts p ON p.id = n.post_id`;

// GET /api/notifications
router.get('/', requireAuth, async (req, res) => {
  try {
    const { rows } = await db.query(
      `${NOTIF_SELECT}
        WHERE n.user_id = $1
        ORDER BY n.created_at DESC
        LIMIT 100`,
      [req.user.id]
    );
    res.json({ notifications: rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /api/notifications/unread-count
router.get('/unread-count', requireAuth, async (req, res) => {
  try {
    const { rows } = await db.query(
      'SELECT COUNT(*)::int AS cnt FROM notifications WHERE user_id = $1 AND read_at IS NULL',
      [req.user.id]
    );
    res.json({ count: rows[0].cnt });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// POST /api/notifications/read-all
router.post('/read-all', requireAuth, async (req, res) => {
  try {
    await db.query(
      'UPDATE notifications SET read_at = NOW() WHERE user_id = $1 AND read_at IS NULL',
      [req.user.id]
    );
    res.json({ ok: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
