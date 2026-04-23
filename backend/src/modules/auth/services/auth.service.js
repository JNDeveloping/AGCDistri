import jwt from 'jsonwebtoken';

import { ROLE_PERMISSIONS } from '../../../config/constants.js';
import { env } from '../../../config/env.js';

export class AuthService {
  generateToken({ userId, email, role }) {
    return jwt.sign({ sub: userId, email, role }, env.jwtSecret, {
      expiresIn: env.jwtExpiresIn,
    });
  }

  verifyToken(token) {
    return jwt.verify(token, env.jwtSecret);
  }

  buildSession(user) {
    const token = this.generateToken({
      userId: user.id,
      email: user.email,
      role: user.role,
    });

    return {
      token,
      user: {
        id: user.id,
        fullName: user.full_name,
        email: user.email,
        role: user.role,
        permissions: ROLE_PERMISSIONS[user.role] ?? [],
      },
    };
  }
}

export const authService = new AuthService();
