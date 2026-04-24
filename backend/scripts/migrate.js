import { runSqlDirectory } from './db-runner.js';

runSqlDirectory('migrations', { backupBefore: true }).catch((error) => {
  console.error(error?.stack ?? error?.message ?? String(error));
  process.exit(1);
});
