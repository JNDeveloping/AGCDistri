import { z } from 'zod';

export const createZoneSchema = z.object({
  name: z.string().trim().min(2).max(120),
  description: z.string().trim().max(600).optional().nullable(),
});

export const updateZoneSchema = z.object({
  name: z.string().trim().min(2).max(120).optional(),
  description: z.string().trim().max(600).optional().nullable(),
});

export const moveZoneClientsSchema = z.object({
  targetZoneId: z.string().uuid(),
});
