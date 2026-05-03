import { z } from 'zod';

import { USER_ROLES } from '../../../config/constants.js';

export const registerSchema = z.object({
  fullName: z.string().min(3).max(120),
  username: z.string().trim().min(3).max(80),
  email: z.string().email(),
  password: z.string().min(8).max(64),
  role: z.enum([USER_ROLES.ADMIN, USER_ROLES.VENDEDOR, USER_ROLES.REPARTIDOR]),
});

export const loginSchema = z.object({
  identifier: z.string().trim().min(1).max(255),
  password: z.string().min(6).max(64),
});
