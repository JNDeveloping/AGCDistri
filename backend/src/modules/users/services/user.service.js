import bcrypt from 'bcryptjs';

import { AppError } from '../../../errors/app-error.js';
import { userRepository } from '../repositories/user.repository.js';

export class UserService {
  async register({ fullName, email, password, role }) {
    const existing = await userRepository.findByEmail(email);
    if (existing) {
      throw new AppError('El correo ya está registrado.', 409);
    }

    const passwordHash = await bcrypt.hash(password, 12);
    return userRepository.create({ fullName, email, passwordHash, role });
  }

  async validateCredentials({ email, password }) {
    const user = await userRepository.findByEmail(email);
    if (!user) {
      throw new AppError('Credenciales inválidas.', 401);
    }

    if (!user.is_active) {
      throw new AppError('El usuario está inactivo.', 403);
    }

    const isValid = await bcrypt.compare(password, user.password_hash);
    if (!isValid) {
      throw new AppError('Credenciales inválidas.', 401);
    }

    return user;
  }

  async getById(id) {
    const user = await userRepository.findById(id);
    if (!user) {
      throw new AppError('Usuario no encontrado.', 404);
    }

    return user;
  }

  async list() {
    return userRepository.list();
  }

  async update(id, payload) {
    const existing = await userRepository.findById(id);
    if (!existing) {
      throw new AppError('Usuario no encontrado.', 404);
    }

    if (payload.email && payload.email.toLowerCase() !== existing.email.toLowerCase()) {
      const duplicated = await userRepository.findByEmail(payload.email);
      if (duplicated) {
        throw new AppError('El correo ya está registrado.', 409);
      }
    }

    let passwordHash;
    if (payload.password) {
      passwordHash = await bcrypt.hash(payload.password, 12);
    }

    return userRepository.update(id, {
      fullName: payload.fullName,
      email: payload.email,
      role: payload.role,
      passwordHash,
    });
  }

  async deactivate(id, actorId) {
    if (id === actorId) {
      throw new AppError('No podés desactivar tu propio usuario.', 400);
    }

    const user = await userRepository.deactivate(id);
    if (!user) {
      throw new AppError('Usuario no encontrado.', 404);
    }

    return user;
  }

  async activate(id, actorId) {
    if (id === actorId) {
      throw new AppError('No podés activar tu propio usuario desde esta acción.', 400);
    }

    const user = await userRepository.activate(id);
    if (!user) {
      throw new AppError('Usuario no encontrado.', 404);
    }

    return user;
  }

  async remove(id, actorId) {
    if (id === actorId) {
      throw new AppError('No podés eliminar el usuario con el que estás logueado.', 409);
    }

    const existing = await userRepository.findById(id);
    if (!existing) {
      throw new AppError('Usuario no encontrado.', 404);
    }

    await userRepository.remove(id);
    return { id };
  }
}

export const userService = new UserService();
