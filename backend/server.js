require('dotenv').config();
const express = require('express');
const cors = require('cors');

const authRoutes    = require('./routes/auth');
const userRoutes    = require('./routes/users');
const postRoutes    = require('./routes/posts');
const reviewRoutes  = require('./routes/reviews');

const app = express();

app.use(cors());
app.use(express.json());

app.get('/health', (_req, res) => res.json({ status: 'ok' }));

app.use('/api/auth',               authRoutes);
app.use('/api/users',              userRoutes);
app.use('/api/posts',              postRoutes);
app.use('/api/recipes/:recipeId/reviews', reviewRoutes);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Chefit backend running on port ${PORT}`));
