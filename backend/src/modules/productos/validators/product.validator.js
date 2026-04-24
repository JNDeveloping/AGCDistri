import { z } from 'zod';

const money = z.number().min(0).max(999999999999.99);
const quantity = z.number().min(0).max(999999999);

export const unitMeasureValues = [
  'Unidad',
  'Pack',
  'Caja',
  'Bulto',
  'Kilogramo',
  'Gramo',
  'Litro',
  'Mililitro',
  'Metro',
  'Centímetro',
  'Docena',
];

const optionalTrimmedString = z.string().transform((value) => value.trim()).pipe(z.string().min(1)).optional().nullable();

export const createProductSchema = z.object({
  internalCode: optionalTrimmedString,
  name: z.string().trim().min(2).max(180),
  shortDescription: z.string().trim().max(220).optional().nullable(),
  longDescription: z.string().trim().max(4000).optional().nullable(),
  brand: z.string().trim().max(120).optional().nullable(),
  categoryId: z.string().uuid().optional().nullable(),
  barcode: optionalTrimmedString,
  unitMeasure: z.enum(unitMeasureValues).optional().nullable(),
  presentation: z.string().trim().max(80).optional().nullable(),
  cost: money,
  wholesalePrice: money,
  retailPrice: money.optional().nullable(),
  marginPercentage: z.number().min(0).max(999).optional().nullable(),
  stockCurrent: quantity.optional().default(0),
  stockMinimum: quantity.optional().default(0),
  isFeatured: z.boolean().optional().default(false),
  imageUrl: z.string().url().optional().nullable(),
  taxRate: z.number().min(0).max(100).optional().nullable(),
  notes: z.string().trim().max(2000).optional().nullable(),
});

export const updateProductSchema = createProductSchema.partial();

export const listProductQuerySchema = z.object({
  q: z.string().optional(),
  isActive: z.enum(['true', 'false']).optional(),
  lowStock: z.enum(['true', 'false']).optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});
