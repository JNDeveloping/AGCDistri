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
}

export const userService = new UserService();
