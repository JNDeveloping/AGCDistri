import pg from 'pg';

import { getDatabaseConnectionConfig } from '../config/database.js';

const { Pool } = pg;

export const pool = new Pool({
  ...getDatabaseConnectionConfig(),
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});
