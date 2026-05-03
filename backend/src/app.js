import cors from 'cors';
import express from 'express';
import helmet from 'helmet';
import morgan from 'morgan';

import { env } from './config/env.js';
import { errorHandler } from './middlewares/error-handler.js';
import { notFoundHandler } from './middlewares/not-found.js';
import { authRouter } from './modules/auth/routes/auth.routes.js';
import { accountRouter, paymentRouter } from './modules/accounts/routes/account.routes.js';
import { clientRouter } from './modules/clientes/routes/client.routes.js';
import { companySettingsRouter } from './modules/company-settings/routes/company-settings.routes.js';
import { dashboardRouter } from './modules/dashboard/routes/dashboard.routes.js';
import { healthRouter } from './modules/health/routes/health.routes.js';
import { operationsRouter } from './modules/operations/routes/operations.routes.js';
import { orderRouter } from './modules/orders/routes/order.routes.js';
import { creditNoteRouter } from './modules/credit-notes/routes/credit-note.routes.js';
import { productVariantRouter } from './modules/product-variants/routes/product-variant.routes.js';
import { productCategoryRouter } from './modules/product-categories/routes/product-category.routes.js';
import { productRouter } from './modules/productos/routes/product.routes.js';
import { stockMovementRouter, stockRouter } from './modules/stock/routes/stock.routes.js';
import { userRouter } from './modules/users/routes/user.routes.js';
import { zoneRouter } from './modules/zones/routes/zone.routes.js';
import { reportRouter } from './modules/reports/routes/report.routes.js';
import { deliveryRouter } from './modules/deliveries/routes/delivery.routes.js';
import { promotionRouter } from './modules/promotions/routes/promotion.routes.js';

const buildCorsOptions = () => {
  const configuredOrigins = (env.corsOrigin ?? '')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);

  if (env.nodeEnv !== 'production') {
    return {
      origin(origin, callback) {
        if (!origin) return callback(null, true);

        const isLocalhost = /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/i.test(origin);
        const isConfigured = configuredOrigins.includes(origin);
        return callback(null, isLocalhost || isConfigured);
      },
      credentials: true,
    };
  }

  return {
    origin(origin, callback) {
      if (!origin) return callback(null, true);
      return callback(null, configuredOrigins.includes(origin));
    },
    credentials: true,
  };
};

export const createApp = () => {
  const app = express();

  app.use(helmet());
  app.use(cors(buildCorsOptions()));
  app.use(morgan('dev'));
  app.use(express.json({ limit: '1mb' }));

  app.use('/health', healthRouter);
  app.use('/api/v1/health', healthRouter);
  app.use('/api/v1/auth', authRouter);
  app.use('/api/v1', accountRouter);
  app.use('/api/v1', paymentRouter);
  app.use('/api/v1/dashboard', dashboardRouter);
  app.use('/api/v1/clientes', clientRouter);
  app.use('/api/v1/clients', clientRouter);
  app.use('/api/v1/company-settings', companySettingsRouter);
  app.use('/api/v1/product-categories', productCategoryRouter);
  app.use('/api/v1/productos', productRouter);
  app.use('/api/v1/stock', stockRouter);
  app.use('/api/v1/stock-movements', stockMovementRouter);
  app.use('/api/v1/operaciones', operationsRouter);
  app.use('/api/v1', deliveryRouter);
  app.use('/api/v1/orders', orderRouter);
  app.use('/api/v1', creditNoteRouter);
  app.use('/api/v1', productVariantRouter);
  app.use('/api/v1/users', userRouter);
  app.use('/api/v1/zones', zoneRouter);
  app.use('/api/v1/reports', reportRouter);
  app.use('/api/v1/promotions', promotionRouter);

  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
};
