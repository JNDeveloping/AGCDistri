import { z } from 'zod';

const money = z.number().min(0).max(999999999999.99);

export const createProductSchema = z.object({
  internalCode: z.string().min(2).max(30),
  name: z.string().min(2).max(180),
  shortDescription: z.string().min(2).max(220),
  longDescription: z.string().max(4000).optional().nullable(),
  brand: z.string().min(2).max(120),
  category: z.string().min(2).max(120),
  segment: z.string().min(2).max(120),
  barcode: z.string().max(80).optional().nullable(),
  unitMeasure: z.string().min(1).max(30),
  presentation: z.string().min(1).max(80),
  cost: money,
  wholesalePrice: money,
  retailPrice: money.optional().nullable(),
  marginPercentage: z.number().min(0).max(999).optional().nullable(),
  stockCurrent: z.number().min(0).max(999999999).default(0),
  stockMinimum: z.number().min(0).max(999999999).default(0),
  isFeatured: z.boolean().optional().default(false),
  imageUrl: z.string().url().optional().nullable(),
  taxRate: z.number().min(0).max(100).optional().nullable(),
});

export const updateProductSchema = createProductSchema.partial();

export const listProductQuerySchema = z.object({
  q: z.string().optional(),
  isActive: z.enum(['true', 'false']).optional(),
  lowStock: z.enum(['true', 'false']).optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});
