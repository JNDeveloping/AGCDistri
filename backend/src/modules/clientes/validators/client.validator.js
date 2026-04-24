import { z } from 'zod';
import { ARGENTINA_PROVINCES, PROVINCE_LOCALITIES } from '../constants/arg-locations.js';

const positiveAmount = z.number().min(0).max(999999999999.99);

export const vatConditionValues = ['Responsable Inscripto', 'Monotributista'];

const baseClientSchema = z.object({
  internalCode: z.string().min(2).max(30),
  businessName: z.string().min(2).max(180),
  phone: z.string().min(6).max(30),
  email: z.string().email().optional().nullable(),
  taxId: z.string().min(6).max(20).optional().nullable(),
  addressLine: z.string().min(4).max(220),
  city: z.string().min(2).max(120),
  province: z.enum(ARGENTINA_PROVINCES),
  routeZone: z.string().min(1).max(80).optional(),
  zoneId: z.string().uuid().optional().nullable(),
  notes: z.string().max(2000).optional().nullable(),
  vatCondition: z.enum(vatConditionValues),
  creditLimit: positiveAmount,
  currentBalance: z.number().min(-999999999999.99).max(999999999999.99).optional(),
  latitude: z.number().min(-90).max(90).optional().nullable(),
  longitude: z.number().min(-180).max(180).optional().nullable(),
});

export const createClientSchema = baseClientSchema.superRefine((value, ctx) => {
  const allowedLocalities = PROVINCE_LOCALITIES[value.province] ?? [];
  if (!allowedLocalities.includes(value.city)) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      path: ['city'],
      message: 'La localidad no corresponde a la provincia seleccionada.',
    });
  }
});

export const updateClientSchema = baseClientSchema.partial().superRefine((value, ctx) => {
  if (!value.province || !value.city) return;
  const allowedLocalities = PROVINCE_LOCALITIES[value.province] ?? [];
  if (!allowedLocalities.includes(value.city)) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      path: ['city'],
      message: 'La localidad no corresponde a la provincia seleccionada.',
    });
  }
});

export const listClientQuerySchema = z.object({
  q: z.string().optional(),
  isActive: z.enum(['true', 'false']).optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});
