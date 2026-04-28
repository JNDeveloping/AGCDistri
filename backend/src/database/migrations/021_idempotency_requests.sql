CREATE TABLE IF NOT EXISTS idempotency_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  action VARCHAR(80) NOT NULL,
  client_request_id VARCHAR(120) NOT NULL,
  response_status INTEGER NOT NULL,
  response_body JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, action, client_request_id)
);

CREATE INDEX IF NOT EXISTS idx_idempotency_requests_created_at
  ON idempotency_requests (created_at DESC);
