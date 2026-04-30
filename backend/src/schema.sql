CREATE TABLE IF NOT EXISTS users (
  id            SERIAL PRIMARY KEY,
  display_name  TEXT,
  bio           TEXT,
  avatar_url    TEXT,
  email         TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  created_at    TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS posts (
  id         SERIAL PRIMARY KEY,
  user_id    INTEGER REFERENCES users(id),
  recipe_id  TEXT,
  caption    TEXT,
  image_url  TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS reviews (
  id         SERIAL PRIMARY KEY,
  user_id    INTEGER REFERENCES users(id),
  recipe_id  TEXT NOT NULL,
  rating     INTEGER CHECK (rating >= 1 AND rating <= 5),
  body       TEXT,
  CONSTRAINT reviews_user_recipe_unique UNIQUE (user_id, recipe_id),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS comments (
  id         SERIAL PRIMARY KEY,
  user_id    INTEGER REFERENCES users(id),
  post_id    INTEGER REFERENCES posts(id),
  body       TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS follows (
  follower_id  INTEGER REFERENCES users(id),
  following_id INTEGER REFERENCES users(id),
  PRIMARY KEY (follower_id, following_id)
);
