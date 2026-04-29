import { z } from 'zod';

const deliveryStatus = z.enum(['pendiente', 'en_reparto', 'finalizado', 'cancelado']);
const deliveryOrderStatus = z.enum(['pendiente', 'entregado', 'no_entregado', 'reprogramado']);

export const listDeliveriesQuerySchema = z.object({
  date: z.string().date().optional(),
  status: deliveryStatus.optional(),
  archived: z.enum(['active', 'archived', 'all']).optional().default('active'),
  driverId: z.string().uuid().optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

export const createDeliverySchema = z
  .object({
    date: z.string().date().optional(),
    driverId: z.string().uuid().optional(),
    driver_id: z.string().uuid().optional(),
    zoneId: z.string().uuid().optional(),
    zone_id: z.string().uuid().optional(),
    orderIds: z.array(z.string().uuid()).min(1).optional(),
    order_ids: z.array(z.string().uuid()).min(1).optional(),
    notes: z.string().trim().max(500).optional(),
  })
  .refine((data) => Boolean(data.zoneId ?? data.zone_id), {
    message: 'zoneId es requerido.',
    path: ['zoneId'],
  })
  .transform((data) => ({
    date: data.date,
    driverId: data.driverId ?? data.driver_id,
    zoneId: data.zoneId ?? data.zone_id,
    orderIds: data.orderIds ?? data.order_ids ?? [],
    notes: data.notes,
  }));

export const changeDeliveryStatusSchema = z.object({
  status: deliveryStatus,
});

export const assignDriverSchema = z.object({
  driverId: z.string().uuid(),
});

export const addOrdersToDeliverySchema = z.object({
  orderIds: z.array(z.string().uuid()).min(1),
});

export const pendingDeliveryOrdersQuerySchema = z
  .object({
    zone_id: z.string().uuid().optional(),
    zoneId: z.string().uuid().optional(),
  })
  .refine((data) => Boolean(data.zone_id ?? data.zoneId), {
    message: 'zone_id es requerido.',
    path: ['zone_id'],
  })
  .transform((data) => ({
    zoneId: data.zoneId ?? data.zone_id,
  }));

export const markDeliveredSchema = z.object({
  clientRequestId: z.string().trim().min(8).max(120).optional(),
  notes: z.string().trim().max(500).optional(),
  collectedCash: z.boolean().optional(),
  collectedAmount: z.coerce.number().min(0).optional(),
});

export const markNotDeliveredSchema = z.object({
  clientRequestId: z.string().trim().min(8).max(120).optional(),
  reason: z.string().trim().min(2).max(500),
  notes: z.string().trim().max(500).optional(),
});

export const markRescheduleSchema = z.object({
  clientRequestId: z.string().trim().min(8).max(120).optional(),
  notes: z.string().trim().max(500).optional(),
});

export const updateDeliveryOrderStatusSchema = z.object({
  status: deliveryOrderStatus,
  notes: z.string().trim().max(500).optional(),
  reason: z.string().trim().max(500).optional(),
  collectedCash: z.boolean().optional(),
  collectedAmount: z.coerce.number().min(0).optional(),
});

export const optimizeRouteSchema = z.object({
  currentLatitude: z.coerce.number().optional(),
  currentLongitude: z.coerce.number().optional(),
});
