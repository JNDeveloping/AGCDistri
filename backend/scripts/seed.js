import { runSqlDirectory } from './db-runner.js';

runSqlDirectory('seeds').catch((error) => {
  console.error(error?.stack ?? error?.message ?? String(error));
  process.exit(1);
});
