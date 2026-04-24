import { createApp } from './app.js';
import { env } from './config/env.js';
import { logger } from './config/logger.js';
import { verifyDatabaseConnection } from './database/healthcheck.js';

const startServer = async () => {
  await verifyDatabaseConnection();

  const app = createApp();

  app.listen(env.port, () => {
    logger.info('API server started', {
      env: env.nodeEnv,
      port: env.port,
    });
  });
};

startServer().catch((error) => {
  logger.error('Server bootstrap failed', { message: error?.message ?? String(error), stack: error?.stack });
  process.exit(1);
});
