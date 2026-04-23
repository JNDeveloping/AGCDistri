import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import dotenv from 'dotenv';
import pg from 'pg';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const backendRoot = path.resolve(__dirname, '..');

dotenv.config({ path: path.join(backendRoot, '.env') });

const { Client } = pg;

const runSqlDirectory = async (directoryName) => {
  const databaseUrl = process.env.DATABASE_URL;

  if (!databaseUrl) {
    throw new Error('DATABASE_URL no está definido. Configuralo en .env o variable de entorno.');
  }

  const sqlDir = path.join(backendRoot, 'src', 'database', directoryName);
  const entries = await fs.readdir(sqlDir);
  const files = entries.filter((file) => file.endsWith('.sql')).sort((a, b) => a.localeCompare(b));

  const client = new Client({ connectionString: databaseUrl });
  await client.connect();

  try {
    for (const file of files) {
      const filePath = path.join(sqlDir, file);
      const sql = await fs.readFile(filePath, 'utf8');
      process.stdout.write(`Applying ${directoryName}: ${file}\n`);
      await client.query(sql);
    }
  } finally {
    await client.end();
  }
};

export { runSqlDirectory };
