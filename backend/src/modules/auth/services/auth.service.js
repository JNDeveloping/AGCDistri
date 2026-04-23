import jwt from 'jsonwebtoken';

import { env } from '../../../config/env.js';

export class AuthService {
  generateToken(payload) {
    return jwt.sign(payload, env.jwtSecret, {
      expiresIn: env.jwtExpiresIn,
    });
  }

  verifyToken(token) {
    return jwt.verify(token, env.jwtSecret);
  }

  buildSession({ userId, email, role }) {
    const token = this.generateToken({ sub: userId, email, role });
    return { userId, email, role, token };
  }
}

export const authService = new AuthService();
