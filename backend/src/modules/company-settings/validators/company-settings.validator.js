import { z } from 'zod';

const hexColorRegex = /^#([A-Fa-f0-9]{6})$/;

const optionalString = z.string().trim().max(220).optional().nullable();

export const upsertCompanySettingsSchema = z.object({
  companyName: z.string().trim().min(2).max(180).optional(),
  logoUrl: z.string().url().optional().nullable(),
  primaryColor: z.string().regex(hexColorRegex, 'Color HEX inválido.').optional().nullable(),
  secondaryColor: z.string().regex(hexColorRegex, 'Color HEX inválido.').optional().nullable(),
  buttonColor: z.string().regex(hexColorRegex, 'Color HEX inválido.').optional().nullable(),
  backgroundColor: z.string().regex(hexColorRegex, 'Color HEX inválido.').optional().nullable(),
  phone: optionalString,
  email: z.string().email().optional().nullable(),
  address: optionalString,
  city: z.string().trim().max(120).optional().nullable(),
  province: z.string().trim().max(120).optional().nullable(),
  taxId: z.string().trim().max(20).optional().nullable(),
  slogan: optionalString,
  defaultProfitPercentage: z.number().min(0).max(9999).optional(),
  priceRoundingEnabled: z.boolean().optional(),
  priceRoundingMultiple: z.number().int().positive().refine((value) => [10, 50, 100].includes(value), {
    message: 'El múltiplo de redondeo debe ser 10, 50 o 100.',
  }).optional(),
}).refine((payload) => Object.keys(payload).length > 0, {
  message: 'Enviá al menos un campo para actualizar.',
});
