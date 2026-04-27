import { runSqlDirectory } from '../../scripts/db-runner.js';

const backupBefore = process.env.BACKUP_BEFORE_MIGRATE === 'true';

runSqlDirectory('migrations', { backupBefore }).catch((error) => {
  console.error(error?.stack ?? error?.message ?? String(error));
  process.exit(1);
});

