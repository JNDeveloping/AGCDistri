import { z } from 'zod';

const money = z.number().min(0).max(999999999999.99).optional().nullable();
const quantity = z.number().min(0).max(999999999).optional().nullable();

export const createProductVariantSchema = z.object({
  name: z.string().trim().min(1).max(180),
  internalCode: z.string().trim().min(1).max(60).optional().nullable(),
  barcode: z.string().trim().min(1).max(80).optional().nullable(),
  price: z.number().min(0).max(999999999999.99),
  cost: money,
  stock: quantity,
});

export const updateProductVariantSchema = createProductVariantSchema;
