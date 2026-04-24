import { z } from 'zod';

export const stockMovementTypes = ['entrada', 'salida', 'ajuste', 'devolucion', 'merma', 'transferencia'];

export const createStockMovementSchema = z.object({
  productId: z.string().uuid(),
  movementType: z.enum(stockMovementTypes),
  quantity: z.coerce.number().positive(),
  reason: z.string().trim().min(2).max(180),
  notes: z.string().trim().max(4000).optional().nullable(),
  referenceType: z.string().trim().max(60).optional().nullable(),
  referenceId: z.string().uuid().optional().nullable(),
  sourceLocation: z.string().trim().max(120).optional().nullable(),
  destinationLocation: z.string().trim().max(120).optional().nullable(),
});

export const adjustStockSchema = z.object({
  productId: z.string().uuid(),
  newStock: z.coerce.number().min(0),
  reason: z.string().trim().min(2).max(180),
  notes: z.string().trim().max(4000).optional().nullable(),
  referenceType: z.string().trim().max(60).optional().nullable(),
  referenceId: z.string().uuid().optional().nullable(),
  sourceLocation: z.string().trim().max(120).optional().nullable(),
  destinationLocation: z.string().trim().max(120).optional().nullable(),
});

export const listStockMovementsQuerySchema = z.object({
  productId: z.string().uuid().optional(),
  type: z.enum(stockMovementTypes).optional(),
  userId: z.string().uuid().optional(),
  dateFrom: z.string().date().optional(),
  dateTo: z.string().date().optional(),
});
