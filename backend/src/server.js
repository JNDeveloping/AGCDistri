import { createApp } from './app.js';
import { env } from './config/env.js';
import { logger } from './config/logger.js';
import { getDatabaseTargetForLogs } from './config/database.js';
import { verifyDatabaseConnection } from './database/healthcheck.js';

const startServer = async () => {
  await verifyDatabaseConnection();
  logger.info('PostgreSQL connection verified', {
    env: env.nodeEnv,
    databaseTarget: getDatabaseTargetForLogs(),
  });

  const app = createApp();
  const PORT = process.env.PORT || 4000;

  app.listen(PORT, '0.0.0.0', () => {
    logger.info('API server started', {
      env: env.nodeEnv,
      port: Number(PORT),
      host: '0.0.0.0',
    });
  });
};

startServer().catch((error) => {
  logger.error('Server bootstrap failed', { message: error?.message ?? String(error), stack: error?.stack });
  process.exit(1);
});
