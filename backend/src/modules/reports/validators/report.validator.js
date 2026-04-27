import { z } from 'zod';

export const reportQuerySchema = z.object({
  dateFrom: z.string().date().optional(),
  dateTo: z.string().date().optional(),
  period: z.enum(['today', 'week', 'month']).optional(),
  clientId: z.string().uuid().optional(),
  sellerId: z.string().uuid().optional(),
  productId: z.string().uuid().optional(),
  category: z.string().trim().min(1).optional(),
  zone: z.string().trim().min(1).optional(),
  paymentTerms: z.enum(['contado', 'cuenta_corriente']).optional(),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});
