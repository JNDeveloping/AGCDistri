import { z } from 'zod';

const hexColorRegex = /^#([A-Fa-f0-9]{6})$/;

const optionalString = z.string().trim().max(220).optional().nullable();

export const upsertCompanySettingsSchema = z.object({
  companyName: z.string().trim().min(2).max(180),
  logoUrl: z.string().url().optional().nullable(),
  primaryColor: z.string().regex(hexColorRegex, 'Color HEX inválido.').optional(),
  secondaryColor: z.string().regex(hexColorRegex, 'Color HEX inválido.').optional(),
  buttonColor: z.string().regex(hexColorRegex, 'Color HEX inválido.').optional(),
  backgroundColor: z.string().regex(hexColorRegex, 'Color HEX inválido.').optional(),
  phone: optionalString,
  email: z.string().email().optional().nullable(),
  address: optionalString,
  city: z.string().trim().max(120).optional().nullable(),
  province: z.string().trim().max(120).optional().nullable(),
  taxId: z.string().trim().max(20).optional().nullable(),
  slogan: optionalString,
  defaultProfitPercentage: z.number().min(0).max(9999),
  priceRoundingEnabled: z.boolean(),
  priceRoundingMultiple: z.number().int().positive().refine((value) => [10, 50, 100].includes(value), {
    message: 'El múltiplo de redondeo debe ser 10, 50 o 100.',
  }),
});
