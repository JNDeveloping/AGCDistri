import { z } from 'zod';

export const createCreditNoteSchema = z.object({
  orderId: z.string().uuid(),
  reason: z.string().trim().min(1).max(220),
  notes: z.string().trim().max(2000).optional().nullable(),
  affectsStock: z.boolean().optional().default(false),
  affectsAccount: z.boolean().optional().default(true),
  items: z.array(z.object({
    productId: z.string().uuid(),
    productNameSnapshot: z.string().trim().min(1).max(220),
    quantity: z.number().positive(),
    unitPrice: z.number().min(0),
    returnToStock: z.boolean().optional().default(false),
    reason: z.string().trim().max(220).optional().nullable(),
  })).min(1),
});

export const listCreditNotesQuerySchema = z.object({
  orderId: z.string().uuid().optional(),
  clientId: z.string().uuid().optional(),
});

