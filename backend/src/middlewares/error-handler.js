import { logger } from '../config/logger.js';
import { AppError } from '../errors/app-error.js';

export const errorHandler = (error, req, res, _next) => {
  const isAppError = error instanceof AppError;
  const statusCode = isAppError ? error.statusCode : 500;

  logger.error('Unhandled API error', {
    path: req.path,
    method: req.method,
    message: error.message,
    stack: error.stack,
  });

  return res.status(statusCode).json({
    success: false,
    message: error.message || 'Internal server error',
    details: isAppError ? error.details : undefined,
  });
};
