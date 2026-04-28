import crypto from 'node:crypto';
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import dotenv from 'dotenv';
import pg from 'pg';

import { createBackup } from './backup.js';
import { getDatabaseConnectionConfig } from '../src/config/database.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const backendRoot = path.resolve(__dirname, '..');

dotenv.config({ path: path.join(backendRoot, '.env') });

const { Client } = pg;

const DESTRUCTIVE_PATTERN = /(DROP\s+TABLE|DROP\s+DATABASE|TRUNCATE(\s+TABLE)?|DELETE\s+FROM)/i;

const ensureMigrationsTable = async (client) => {
  await client.query(`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      id BIGSERIAL PRIMARY KEY,
      migration_name TEXT NOT NULL UNIQUE,
      checksum TEXT,
      executed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `);
};

const computeChecksum = (content) => crypto.createHash('sha256').update(content, 'utf8').digest('hex');

const assertSafeSql = ({ sql, fileName, mode }) => {
  if (!DESTRUCTIVE_PATTERN.test(sql)) return;

  const explicitAllowed = sql.includes('DESTRUCTIVE_OK');
  const isDevelopment = process.env.NODE_ENV === 'development';
  const hasManualConfirmation = process.env.CONFIRM_DESTRUCTIVE === 'true';

  if (mode === 'migrations' && explicitAllowed && isDevelopment && hasManualConfirmation) {
    return;
  }

  throw new Error(
    `Migración bloqueada por operación destructiva detectada en ${fileName}. `
      + 'No se permiten DROP TABLE/TRUNCATE/DELETE masivo sin confirmación explícita y entorno development.',
  );
};

const markMigration = async (client, migrationName, checksum) => {
  await client.query(
    `
      INSERT INTO schema_migrations (migration_name, checksum)
      VALUES ($1, $2)
      ON CONFLICT (migration_name) DO NOTHING
    `,
    [migrationName, checksum],
  );
};

const wasExecuted = async (client, migrationName) => {
  const { rows } = await client.query(
    'SELECT checksum FROM schema_migrations WHERE migration_name = $1 LIMIT 1',
    [migrationName],
  );

  return rows[0] ?? null;
};

const runSqlDirectory = async (directoryName, { backupBefore = false } = {}) => {
  if (backupBefore) {
    await createBackup();
  }

  const sqlDir = path.join(backendRoot, 'src', 'database', directoryName);
  const entries = await fs.readdir(sqlDir);
  const files = entries.filter((file) => file.endsWith('.sql')).sort((a, b) => a.localeCompare(b));

  const client = new Client(getDatabaseConnectionConfig());
  await client.connect();

  try {
    if (directoryName === 'migrations') {
      await ensureMigrationsTable(client);
    }

    for (const file of files) {
      const filePath = path.join(sqlDir, file);
      const sql = await fs.readFile(filePath, 'utf8');

      if (directoryName === 'migrations') {
        const existingMigration = await wasExecuted(client, file);
        if (existingMigration) {
          const checksum = computeChecksum(sql);
          if (existingMigration.checksum && existingMigration.checksum !== checksum) {
            throw new Error(
              `La migración ${file} ya fue ejecutada pero su contenido cambió. `
              + 'Creá una nueva migración incremental en lugar de editar una existente.',
            );
          }

          process.stdout.write(`Skipping ${directoryName}: ${file} (already executed)\n`);
          continue;
        }

        assertSafeSql({ sql, fileName: file, mode: directoryName });

        await client.query('BEGIN');
        try {
          process.stdout.write(`Applying ${directoryName}: ${file}\n`);
          await client.query(sql);
          await markMigration(client, file, computeChecksum(sql));
          await client.query('COMMIT');
        } catch (error) {
          await client.query('ROLLBACK');
          throw error;
        }
      } else {
        assertSafeSql({ sql, fileName: file, mode: directoryName });
        process.stdout.write(`Applying ${directoryName}: ${file}\n`);
        await client.query(sql);
      }
    }
  } finally {
    await client.end();
  }
};

export { runSqlDirectory };
