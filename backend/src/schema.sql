CREATE TABLE IF NOT EXISTS users (
  id            SERIAL PRIMARY KEY,
  display_name  TEXT,
  bio           TEXT,
  avatar_url    TEXT,
  email         TEXT UNIQUE NOT NULL,
  password_hash TEXT,
  auth_provider TEXT DEFAULT 'local',
  provider_id   TEXT,
  created_at    TIMESTAMP DEFAULT NOW()
);

-- Migrate existing tables: allow OAuth users without passwords
ALTER TABLE users ALTER COLUMN password_hash DROP NOT NULL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS auth_provider TEXT DEFAULT 'local';
ALTER TABLE users ADD COLUMN IF NOT EXISTS provider_id TEXT;

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

CREATE TABLE IF NOT EXISTS post_likes (
  user_id    INTEGER REFERENCES users(id),
  post_id    INTEGER REFERENCES posts(id),
  created_at TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (user_id, post_id)
);

CREATE INDEX IF NOT EXISTS idx_post_likes_post ON post_likes(post_id);

CREATE TABLE IF NOT EXISTS notifications (
  id          SERIAL PRIMARY KEY,
  user_id     INTEGER NOT NULL REFERENCES users(id),
  actor_id    INTEGER NOT NULL REFERENCES users(id),
  type        TEXT NOT NULL,
  post_id     INTEGER REFERENCES posts(id),
  comment_id  INTEGER REFERENCES comments(id),
  read_at     TIMESTAMP,
  created_at  TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id, created_at DESC);
CREATE UNIQUE INDEX IF NOT EXISTS idx_notifications_like_unique
  ON notifications(user_id, actor_id, post_id)
  WHERE type = 'like';
