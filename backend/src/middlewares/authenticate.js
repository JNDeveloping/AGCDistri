import { AppError } from '../errors/app-error.js';
import { authService } from '../modules/auth/services/auth.service.js';

export const authenticate = (req, _res, next) => {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    throw new AppError('Token de autenticación faltante.', 401);
  }

  const token = header.replace('Bearer ', '');

  try {
    req.user = authService.verifyToken(token);
    return next();
  } catch {
    throw new AppError('Token inválido o expirado.', 401);
  }
};
