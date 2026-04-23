import { authService } from '../modules/auth/services/auth.service.js';

export const authenticate = (req, res, next) => {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    return res.status(401).json({ success: false, message: 'Missing bearer token' });
  }

  const token = header.replace('Bearer ', '');

  try {
    req.user = authService.verifyToken(token);
    return next();
  } catch {
    return res.status(401).json({ success: false, message: 'Invalid token' });
  }
};
