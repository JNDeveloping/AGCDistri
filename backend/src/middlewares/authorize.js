import { AppError } from '../errors/app-error.js';

export const authorize = (...roles) => {
  return (req, _res, next) => {
    const userRole = req.user?.role;

    if (!userRole || !roles.includes(userRole)) {
      throw new AppError('No autorizado para este recurso.', 403);
    }

    return next();
  };
};
