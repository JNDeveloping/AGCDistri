import { ok } from '../../../utils/api-response.js';
import { authService } from '../services/auth.service.js';

export const loginController = async (req, res) => {
  const { email } = req.body;

  const session = authService.buildSession({
    userId: 'pending-db-user-id',
    email,
    role: 'seller',
  });

  return ok(res, session, 'JWT emitido correctamente. Reemplazar por validación real con PostgreSQL.');
};

export const meController = async (req, res) => {
  return ok(res, {
    userId: req.user.sub,
    email: req.user.email,
    role: req.user.role,
  });
};
