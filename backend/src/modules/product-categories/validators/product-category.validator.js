import { z } from 'zod';

export const createProductCategorySchema = z.object({
  name: z.string().trim().min(2).max(120),
  description: z.string().trim().max(1000).optional().nullable(),
});

export const updateProductCategorySchema = createProductCategorySchema.partial();

export const listCategoryQuerySchema = z.object({
  includeInactive: z.enum(['true', 'false']).optional(),
});

export const moveCategoryProductsSchema = z.object({
  categoryId: z.string().uuid(),
});
