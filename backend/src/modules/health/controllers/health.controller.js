import { pool } from '../../../database/pool.js';

export const healthController = async (_req, res) => {
  let database = 'disconnected';

  try {
    await pool.query('SELECT 1');
    database = 'connected';
  } catch {
    database = 'disconnected';
  }

  const payload = {
    status: 'ok',
    service: 'backend',
    timestamp: new Date().toISOString(),
    database,
  };

  const statusCode = database === 'connected' ? 200 : 503;
  return res.status(statusCode).json(payload);
};
