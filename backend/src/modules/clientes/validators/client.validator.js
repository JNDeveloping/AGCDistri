import { z } from 'zod';

const positiveAmount = z.number().min(0).max(999999999999.99);

export const createClientSchema = z.object({
  internalCode: z.string().min(2).max(30),
  businessName: z.string().min(2).max(180),
  contactName: z.string().min(2).max(120),
  phone: z.string().min(6).max(30),
  alternatePhone: z.string().max(30).optional().nullable(),
  email: z.string().email().optional().nullable(),
  taxId: z.string().min(6).max(20).optional().nullable(),
  addressLine: z.string().min(4).max(220),
  city: z.string().min(2).max(120),
  province: z.string().min(2).max(120),
  routeZone: z.string().min(1).max(80),
  notes: z.string().max(2000).optional().nullable(),
  vatCondition: z.string().min(2).max(80),
  creditLimit: positiveAmount,
  currentBalance: z.number().min(-999999999999.99).max(999999999999.99).optional(),
  latitude: z.number().min(-90).max(90).optional().nullable(),
  longitude: z.number().min(-180).max(180).optional().nullable(),
});

export const updateClientSchema = createClientSchema.partial();

export const listClientQuerySchema = z.object({
  q: z.string().optional(),
  isActive: z.enum(['true', 'false']).optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});
