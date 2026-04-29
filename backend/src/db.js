require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

pool.query('SELECT 1')
  .then(() => console.log('DB connected'))
  .catch(err => console.error('DB connection failed:', err.message));

module.exports = {
  query: (text, params) => pool.query(text, params),
};
