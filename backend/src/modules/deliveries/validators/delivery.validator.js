import { z } from 'zod';

const deliveryStatus = z.enum(['pendiente', 'en_preparacion', 'en_reparto', 'finalizado', 'cancelado']);
const deliveryOrderStatus = z.enum(['pendiente', 'entregado', 'no_entregado', 'reprogramado']);

export const listDeliveriesQuerySchema = z.object({
  date: z.string().date().optional(),
  status: deliveryStatus.optional(),
  driverId: z.string().uuid().optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

export const createDeliverySchema = z.object({
  date: z.string().date().optional(),
  driverId: z.string().uuid().optional(),
  notes: z.string().trim().max(500).optional(),
  zone: z.string().trim().max(120).optional(),
});

export const changeDeliveryStatusSchema = z.object({
  status: deliveryStatus,
});

export const assignDriverSchema = z.object({
  driverId: z.string().uuid(),
});

export const addOrdersToDeliverySchema = z.object({
  orderIds: z.array(z.string().uuid()).min(1),
});

export const pendingDeliveryOrdersQuerySchema = z.object({
  zone: z.string().trim().min(1).optional(),
});

export const updateDeliveryOrderStatusSchema = z
  .object({
    status: deliveryOrderStatus,
    notes: z.string().trim().max(500).optional(),
    reason: z.string().trim().max(500).optional(),
    collectedCash: z.boolean().optional(),
    collectedAmount: z.coerce.number().min(0).optional(),
  })
  .superRefine((value, ctx) => {
    if (value.status === 'no_entregado' && !value.reason) {
      ctx.addIssue({ code: z.ZodIssueCode.custom, path: ['reason'], message: 'El motivo es obligatorio cuando no se entrega.' });
    }
  });

export const optimizeRouteSchema = z.object({
  currentLatitude: z.coerce.number().optional(),
  currentLongitude: z.coerce.number().optional(),
});
