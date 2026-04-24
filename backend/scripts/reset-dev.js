import path from 'node:path';
import { fileURLToPath } from 'node:url';

import dotenv from 'dotenv';
import pg from 'pg';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const backendRoot = path.resolve(__dirname, '..');

dotenv.config({ path: path.join(backendRoot, '.env') });

const { Client } = pg;

const run = async () => {
  if (process.env.NODE_ENV !== 'development') {
    throw new Error('reset:dev está bloqueado fuera de development.');
  }

  if (process.env.CONFIRM_RESET_DEV !== 'true') {
    throw new Error(
      'reset:dev es destructivo. Reintentá con CONFIRM_RESET_DEV=true para confirmar manualmente.',
    );
  }

  const databaseUrl = process.env.DATABASE_URL;
  if (!databaseUrl) {
    throw new Error('DATABASE_URL no está definido. Configuralo en .env o variable de entorno.');
  }

  const client = new Client({ connectionString: databaseUrl });
  await client.connect();

  try {
    await client.query('DROP SCHEMA public CASCADE; CREATE SCHEMA public;');
    process.stdout.write('Base de desarrollo reiniciada (schema public recreado).\n');
  } finally {
    await client.end();
  }
};

run().catch((error) => {
  console.error(error?.stack ?? error?.message ?? String(error));
  process.exit(1);
});
