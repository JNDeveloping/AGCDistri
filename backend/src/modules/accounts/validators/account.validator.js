import { z } from 'zod';

const accountTypes = ['deuda', 'pago', 'ajuste', 'nota_credito', 'saldo_a_favor', 'anulacion'];
const paymentMethods = ['efectivo', 'transferencia', 'cheque', 'mercado_pago', 'otro'];

export const createAccountMovementSchema = z.object({
  movementType: z.enum(accountTypes),
  amount: z.coerce.number().positive(),
  description: z.string().trim().min(2).max(255),
  notes: z.string().trim().max(4000).optional().nullable(),
  referenceType: z.string().trim().max(60).optional().nullable(),
  referenceId: z.string().uuid().optional().nullable(),
});

export const adjustAccountSchema = z.object({
  amount: z.coerce.number().positive(),
  description: z.string().trim().min(2).max(255),
  notes: z.string().trim().max(4000).optional().nullable(),
  referenceType: z.string().trim().max(60).optional().nullable(),
  referenceId: z.string().uuid().optional().nullable(),
});

export const listAccountMovementsQuerySchema = z.object({
  type: z.enum(accountTypes).optional(),
  dateFrom: z.string().date().optional(),
  dateTo: z.string().date().optional(),
});

export const createClientPaymentSchema = z.object({
  clientId: z.string().uuid(),
  amount: z.coerce.number().positive(),
  paymentMethod: z.enum(paymentMethods),
  notes: z.string().trim().max(4000).optional().nullable(),
  referenceType: z.string().trim().max(60).optional().nullable(),
  referenceId: z.string().uuid().optional().nullable(),
});

export const listPaymentsQuerySchema = z.object({
  clientId: z.string().uuid().optional(),
  userId: z.string().uuid().optional(),
  method: z.enum(paymentMethods).optional(),
  dateFrom: z.string().date().optional(),
  dateTo: z.string().date().optional(),
});
