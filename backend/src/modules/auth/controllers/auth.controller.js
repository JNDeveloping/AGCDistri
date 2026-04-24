import { ROLE_PERMISSIONS } from '../../../config/constants.js';
import { pool } from '../../../database/pool.js';
import { ok } from '../../../utils/api-response.js';
import { authService } from '../services/auth.service.js';
import { userService } from '../../users/services/user.service.js';

const recordAudit = async ({ action, userId, metadata }) => {
  const query = `
    INSERT INTO audit_logs (user_id, action, metadata)
    VALUES ($1, $2, $3)
  `;

  await pool.query(query, [userId, action, metadata]);
};

export const registerController = async (req, res) => {
  const user = await userService.register(req.body);
  await recordAudit({ action: 'USER_REGISTER', userId: user.id, metadata: { email: user.email } });

  return ok(
    res,
    {
      id: user.id,
      fullName: user.full_name,
      email: user.email,
      role: user.role,
      isActive: user.is_active,
      createdAt: user.created_at,
    },
    'Usuario registrado correctamente.',
  );
};

export const loginController = async (req, res) => {
  const user = await userService.validateCredentials(req.body);
  const session = authService.buildSession(user);

  await recordAudit({ action: 'USER_LOGIN', userId: user.id, metadata: { role: user.role } });

  return ok(res, session, 'Inicio de sesión correcto.');
};

export const meController = async (req, res) => {
  const user = await userService.getById(req.user.sub);
  return ok(res, {
    id: user.id,
    fullName: user.full_name,
    email: user.email,
    role: user.role,
    permissions: ROLE_PERMISSIONS[user.role] ?? [],
  });
};
