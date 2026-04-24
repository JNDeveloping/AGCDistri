import cors from 'cors';
import express from 'express';
import helmet from 'helmet';
import morgan from 'morgan';

import { env } from './config/env.js';
import { errorHandler } from './middlewares/error-handler.js';
import { notFoundHandler } from './middlewares/not-found.js';
import { authRouter } from './modules/auth/routes/auth.routes.js';
import { clientRouter } from './modules/clientes/routes/client.routes.js';
import { companySettingsRouter } from './modules/company-settings/routes/company-settings.routes.js';
import { dashboardRouter } from './modules/dashboard/routes/dashboard.routes.js';
import { healthRouter } from './modules/health/routes/health.routes.js';
import { operationsRouter } from './modules/operations/routes/operations.routes.js';
import { orderRouter } from './modules/orders/routes/order.routes.js';
import { productCategoryRouter } from './modules/product-categories/routes/product-category.routes.js';
import { productRouter } from './modules/productos/routes/product.routes.js';
import { userRouter } from './modules/users/routes/user.routes.js';
import { zoneRouter } from './modules/zones/routes/zone.routes.js';

export const createApp = () => {
  const app = express();

  app.use(helmet());
  app.use(cors({ origin: env.corsOrigin }));
  app.use(morgan('dev'));
  app.use(express.json({ limit: '1mb' }));

  app.use('/api/v1/health', healthRouter);
  app.use('/api/v1/auth', authRouter);
  app.use('/api/v1/dashboard', dashboardRouter);
  app.use('/api/v1/clientes', clientRouter);
  app.use('/api/v1/clients', clientRouter);
  app.use('/api/v1/company-settings', companySettingsRouter);
  app.use('/api/v1/product-categories', productCategoryRouter);
  app.use('/api/v1/productos', productRouter);
  app.use('/api/v1/operaciones', operationsRouter);
  app.use('/api/v1/orders', orderRouter);
  app.use('/api/v1/users', userRouter);
  app.use('/api/v1/zones', zoneRouter);

  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
};
