import { logger } from '../config/logger.js';
import { AppError } from '../errors/app-error.js';

export const errorHandler = (error, req, res, _next) => {
  let normalizedError = error;

  if (!(error instanceof AppError) && error?.code === '42P01') {
    normalizedError = new AppError(
      'La base de datos no tiene las tablas requeridas. Ejecutá las migraciones con "npm run db:migrate" en /backend.',
      503,
      { postgresCode: error.code, postgresMessage: error.message },
    );
  }

  const isAppError = normalizedError instanceof AppError;
  const statusCode = isAppError ? normalizedError.statusCode : 500;
  const details = isAppError ? normalizedError.details : undefined;
  const stockError = details?.code === 'INSUFFICIENT_STOCK'
    ? {
        code: details.code,
        productName: details.productName,
        variantName: details.variantName,
        availableStock: details.availableStock,
      }
    : {};

  const logContext = {
    path: req.path,
    method: req.method,
    statusCode,
    message: normalizedError.message,
    postgresCode: error?.code,
  };

  if (!isAppError || statusCode >= 500) {
    logger.error('Unhandled API error', {
      ...logContext,
      stack: normalizedError.stack,
    });
  } else {
    logger.info('Handled API error', logContext);
  }

  return res.status(statusCode).json({
    success: false,
    message: normalizedError.message || 'Internal server error',
    ...stockError,
  });
};
