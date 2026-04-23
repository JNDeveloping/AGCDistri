import { pool } from './pool.js';

export const verifyDatabaseConnection = async () => {
  const client = await pool.connect();
  try {
    await client.query('SELECT 1');
  } finally {
    client.release();
  }
};
