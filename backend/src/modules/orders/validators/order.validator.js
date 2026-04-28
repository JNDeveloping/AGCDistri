import { z } from 'zod';

export const orderStatusValues = ['pendiente', 'preparado', 'en_reparto', 'entregado', 'cancelado'];
export const paymentTermsValues = ['contado', 'cuenta_corriente'];

const orderItemSchema = z.object({
  productId: z.string().uuid(),
  productVariantId: z.string().uuid().optional().nullable(),
  quantity: z.coerce.number().positive(),
  discountType: z.enum(['amount', 'percentage']).optional().default('amount'),
  discountValue: z.coerce.number().min(0).optional().default(0),
  discountAmount: z.coerce.number().min(0).optional().default(0),
});

export const createOrderSchema = z.object({
  clientId: z.string().uuid(),
  notes: z.string().max(4000).optional().nullable(),
  paymentTerms: z.enum(paymentTermsValues).optional().default('contado'),
  discountTotal: z.coerce.number().min(0).optional().default(0),
  estimatedDeliveryDate: z.string().date().optional().nullable(),
  items: z.array(orderItemSchema).min(1),
});

export const updateOrderSchema = createOrderSchema;

export const changeOrderStatusSchema = z.object({
  status: z.enum(orderStatusValues),
});

export const listOrdersQuerySchema = z.object({
  clientId: z.string().uuid().optional(),
  sellerId: z.string().uuid().optional(),
  zoneId: z.string().uuid().optional(),
  status: z.enum(orderStatusValues).optional(),
  paymentCondition: z.enum(paymentTermsValues).optional(),
  search: z.string().trim().min(1).max(120).optional(),
  sortBy: z.enum(['orderDate', 'total', 'client', 'zone', 'status']).optional(),
  sortDirection: z.enum(['asc', 'desc']).optional(),
  dateFrom: z.string().date().optional(),
  dateTo: z.string().date().optional(),
  orderNumber: z.coerce.number().int().positive().optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});
