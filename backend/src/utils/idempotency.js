import { pool } from '../database/pool.js';

const normalizeClientRequestId = (value) => {
  const normalized = String(value ?? '').trim();
  return normalized.length ? normalized : null;
};

export const runIdempotent = async ({ userId, action, clientRequestId, execute }) => {
  const normalized = normalizeClientRequestId(clientRequestId);
  if (!normalized) {
    return execute();
  }

  const existing = await pool.query(
    `SELECT response_status, response_body
     FROM idempotency_requests
     WHERE user_id = $1 AND action = $2 AND client_request_id = $3
     LIMIT 1`,
    [userId, action, normalized],
  );

  if (existing.rows[0]) {
    return {
      statusCode: Number(existing.rows[0].response_status),
      body: existing.rows[0].response_body,
      replayed: true,
    };
  }

  const result = await execute();

  await pool.query(
    `INSERT INTO idempotency_requests (user_id, action, client_request_id, response_status, response_body)
     VALUES ($1, $2, $3, $4, $5::jsonb)
     ON CONFLICT (user_id, action, client_request_id)
     DO NOTHING`,
    [userId, action, normalized, result.statusCode, JSON.stringify(result.body)],
  );

  return { ...result, replayed: false };
};
