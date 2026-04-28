import { created, ok } from '../../../utils/api-response.js';
import { userService } from '../services/user.service.js';

const toUserDto = (user) => ({
  id: user.id,
  fullName: user.full_name,
  username: user.username,
  email: user.email,
  role: user.role,
  isActive: user.is_active,
  createdAt: user.created_at,
  updatedAt: user.updated_at,
});

export const listUsersController = async (_req, res) => {
  const users = await userService.list();
  return ok(res, users.map(toUserDto), 'Usuarios obtenidos correctamente.');
};

export const createUserController = async (req, res) => {
  const user = await userService.register(req.body);
  return created(res, toUserDto(user), 'Usuario creado correctamente.');
};

export const updateUserController = async (req, res) => {
  const user = await userService.update(req.params.id, req.body);
  return ok(res, toUserDto(user), 'Usuario actualizado correctamente.');
};

export const deactivateUserController = async (req, res) => {
  const user = await userService.deactivate(req.params.id, req.user.sub);
  return ok(res, toUserDto(user), 'Usuario desactivado correctamente.');
};

export const activateUserController = async (req, res) => {
  const user = await userService.activate(req.params.id, req.user.sub);
  return ok(res, toUserDto(user), 'Usuario activado correctamente.');
};

export const deleteUserController = async (req, res) => {
  const result = await userService.remove(req.params.id, req.user.sub);
  return ok(res, result, 'Usuario eliminado correctamente.');
};
