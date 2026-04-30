const router = require('express').Router({ mergeParams: true });
const db = require('../db');
const requireAuth = require('../middleware/auth');

// Get reviews for a recipe
router.get('/', async (req, res) => {
  try {
    const { rows } = await db.query(
      `SELECT r.id, r.rating, r.body, r.created_at,
              u.id AS user_id, u.display_name, u.avatar_url
         FROM reviews r
         JOIN users u ON u.id = r.user_id
        WHERE r.recipe_id = $1
        ORDER BY r.created_at DESC`,
      [req.params.recipeId]
    );
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// Add or update review (one per user per recipe)
router.post('/', requireAuth, async (req, res) => {
  const { rating, body } = req.body;
  if (!rating || rating < 1 || rating > 5) {
    return res.status(400).json({ error: 'rating must be 1–5' });
  }

  try {
    const { rows } = await db.query(
      `INSERT INTO reviews (user_id, recipe_id, rating, body)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (user_id, recipe_id) DO UPDATE
         SET rating = EXCLUDED.rating, body = EXCLUDED.body, created_at = NOW()
       RETURNING *`,
      [req.user.id, req.params.recipeId, rating, body || null]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
