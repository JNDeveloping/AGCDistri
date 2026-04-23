import { runSqlDirectory } from './db-runner.js';

runSqlDirectory('migrations').catch((error) => {
  console.error(error?.stack ?? error?.message ?? String(error));
  process.exit(1);
});
