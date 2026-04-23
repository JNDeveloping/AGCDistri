import { logger } from '../config/logger.js';

export const errorHandler = (error, req, res, next) => {
  logger.error('Unhandled API error', {
    path: req.path,
    method: req.method,
    message: error.message,
  });

  return res.status(500).json({
    success: false,
    message: 'Internal server error',
  });
};
