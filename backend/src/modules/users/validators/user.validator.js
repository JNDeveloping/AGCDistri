import { z } from 'zod';

import { USER_ROLES } from '../../../config/constants.js';

const roleEnum = z.enum([USER_ROLES.ADMIN, USER_ROLES.VENDEDOR, USER_ROLES.REPARTIDOR]);

export const createUserSchema = z.object({
  fullName: z.string().trim().min(3).max(120),
  email: z.string().trim().email().max(255),
  password: z.string().min(8).max(120),
  role: roleEnum,
});

export const updateUserSchema = z.object({
  fullName: z.string().trim().min(3).max(120).optional(),
  email: z.string().trim().email().max(255).optional(),
  password: z.string().min(8).max(120).optional(),
  role: roleEnum.optional(),
});
