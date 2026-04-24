import { z } from 'zod';

export const orderStatusValues = ['pendiente', 'confirmado', 'preparado', 'en_reparto', 'entregado', 'cancelado'];

const orderItemSchema = z.object({
  productId: z.string().uuid(),
  quantity: z.coerce.number().positive(),
  discountAmount: z.coerce.number().min(0).optional().default(0),
});

export const createOrderSchema = z.object({
  clientId: z.string().uuid(),
  notes: z.string().max(4000).optional().nullable(),
  paymentTerms: z.string().max(120).optional().nullable(),
  discountTotal: z.coerce.number().min(0).optional().default(0),
  taxTotal: z.coerce.number().min(0).optional().default(0),
  deliveryAddress: z.string().max(255).optional().nullable(),
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
  status: z.enum(orderStatusValues).optional(),
  dateFrom: z.string().date().optional(),
  dateTo: z.string().date().optional(),
  orderNumber: z.coerce.number().int().positive().optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});
