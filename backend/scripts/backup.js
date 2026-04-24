import { spawn } from 'node:child_process';
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import dotenv from 'dotenv';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const backendRoot = path.resolve(__dirname, '..');

dotenv.config({ path: path.join(backendRoot, '.env') });

const timestamp = () => {
  const now = new Date();
  const year = now.getUTCFullYear();
  const month = String(now.getUTCMonth() + 1).padStart(2, '0');
  const day = String(now.getUTCDate()).padStart(2, '0');
  const hours = String(now.getUTCHours()).padStart(2, '0');
  const minutes = String(now.getUTCMinutes()).padStart(2, '0');
  const seconds = String(now.getUTCSeconds()).padStart(2, '0');

  return `${year}-${month}-${day}_${hours}${minutes}${seconds}`;
};

const runPgDump = async (outputPath, databaseUrl) => new Promise((resolve, reject) => {
  const child = spawn('pg_dump', ['--no-owner', '--no-privileges', '--file', outputPath, databaseUrl], {
    stdio: ['ignore', 'pipe', 'pipe'],
  });

  let stderr = '';
  child.stderr.on('data', (chunk) => {
    stderr += chunk.toString();
  });

  child.on('error', (error) => {
    reject(new Error(`No se pudo ejecutar pg_dump: ${error.message}`));
  });

  child.on('close', (code) => {
    if (code === 0) {
      resolve();
      return;
    }

    reject(new Error(`pg_dump finalizó con código ${code}. ${stderr}`.trim()));
  });
});

const createBackup = async () => {
  const databaseUrl = process.env.DATABASE_URL;
  if (!databaseUrl) {
    throw new Error('DATABASE_URL no está definido. No se puede crear backup.');
  }

  const backupDir = path.join(backendRoot, 'backups');
  await fs.mkdir(backupDir, { recursive: true });

  const fileName = `backup_${timestamp()}.sql`;
  const backupPath = path.join(backupDir, fileName);
  await runPgDump(backupPath, databaseUrl);
  process.stdout.write(`Backup generado: ${backupPath}\n`);
  return backupPath;
};

if (process.argv[1] === __filename) {
  createBackup().catch((error) => {
    console.error(error?.stack ?? error?.message ?? String(error));
    process.exit(1);
  });
}

export { createBackup };
