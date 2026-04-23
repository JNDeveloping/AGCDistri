import cors from 'cors';
import express from 'express';
import helmet from 'helmet';
import morgan from 'morgan';

import { env } from './config/env.js';
import { errorHandler } from './middlewares/error-handler.js';
import { notFoundHandler } from './middlewares/not-found.js';
import { authRouter } from './modules/auth/routes/auth.routes.js';
import { clientRouter } from './modules/clientes/routes/client.routes.js';
import { healthRouter } from './modules/health/routes/health.routes.js';
import { operationsRouter } from './modules/operations/routes/operations.routes.js';

export const createApp = () => {
  const app = express();

  app.use(helmet());
  app.use(cors({ origin: env.corsOrigin }));
  app.use(morgan('dev'));
  app.use(express.json({ limit: '1mb' }));

  app.use('/api/v1/health', healthRouter);
  app.use('/api/v1/auth', authRouter);
  app.use('/api/v1/clientes', clientRouter);
  app.use('/api/v1/operaciones', operationsRouter);

  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
};
