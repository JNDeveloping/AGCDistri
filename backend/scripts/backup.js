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

const resolveWindowsPgDumpCandidates = async () => {
  if (process.platform !== 'win32') return [];

  const roots = [process.env['ProgramFiles'], process.env['ProgramFiles(x86)']].filter(Boolean);
  const candidates = [];

  for (const root of roots) {
    const postgresDir = path.join(root, 'PostgreSQL');
    try {
      const versions = await fs.readdir(postgresDir, { withFileTypes: true });
      for (const entry of versions) {
        if (!entry.isDirectory()) continue;
        candidates.push(path.join(postgresDir, entry.name, 'bin', 'pg_dump.exe'));
      }
    } catch {
      // ignore missing directories
    }
  }

  return candidates.sort((a, b) => b.localeCompare(a));
};

const resolvePgDumpCommand = async () => {
  if (process.env.PG_DUMP_BIN) {
    return process.env.PG_DUMP_BIN;
  }

  if (process.platform === 'win32') {
    const windowsCandidates = await resolveWindowsPgDumpCandidates();
    for (const candidate of windowsCandidates) {
      try {
        await fs.access(candidate);
        return candidate;
      } catch {
        // keep searching
      }
    }
  }

  return 'pg_dump';
};

const runPgDump = async (outputPath, databaseUrl) => {
  const pgDumpCmd = await resolvePgDumpCommand();

  return new Promise((resolve, reject) => {
    const child = spawn(pgDumpCmd, ['--no-owner', '--no-privileges', '--file', outputPath, databaseUrl], {
      stdio: ['ignore', 'pipe', 'pipe'],
    });

  let stderr = '';
    child.stderr.on('data', (chunk) => {
      stderr += chunk.toString();
    });

    child.on('error', (error) => {
      reject(
        new Error(
          `No se pudo ejecutar pg_dump (${pgDumpCmd}): ${error.message}. `
          + 'Instalá PostgreSQL client tools o definí PG_DUMP_BIN con la ruta a pg_dump.',
        ),
      );
    });

    child.on('close', (code) => {
      if (code === 0) {
        resolve();
        return;
      }

      reject(new Error(`pg_dump finalizó con código ${code}. ${stderr}`.trim()));
    });
  });
};

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
