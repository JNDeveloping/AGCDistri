ALTER TABLE users
  ADD COLUMN IF NOT EXISTS username VARCHAR(80);

UPDATE users
SET username = LOWER(split_part(email, '@', 1))
WHERE username IS NULL;

ALTER TABLE users
  ALTER COLUMN username SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_users_username_unique ON users(username);
