import { z } from 'zod';

export const promotionTypes = ['quantity_discount','bulk_discount','tiered_discount','combo','x_for_y','order_total_discount','target_discount','stock_discount'];
const discountTypes = ['percentage','fixed_amount','fixed_price'];

const promotionItemSchema = z.object({
  productId: z.string().uuid().optional().nullable(),
  variantId: z.string().uuid().optional().nullable(),
  categoryId: z.string().uuid().optional().nullable(),
  requiredQuantity: z.coerce.number().positive().optional().default(1),
  unitsPerBulto: z.coerce.number().positive().optional().nullable(),
});

const promotionTierSchema = z.object({
  minQuantity: z.coerce.number().positive(),
  discountType: z.enum(discountTypes),
  discountValue: z.coerce.number().min(0).optional().nullable(),
  fixedUnitPrice: z.coerce.number().min(0).optional().nullable(),
});

export const upsertPromotionSchema = z.object({
  name: z.string().trim().min(2),
  description: z.string().optional().nullable(),
  type: z.enum(promotionTypes),
  isActive: z.boolean().optional().default(true),
  startDate: z.string().datetime().optional().nullable(),
  endDate: z.string().datetime().optional().nullable(),
  priority: z.coerce.number().int().optional().default(0),
  stackable: z.boolean().optional().default(false),
  appliesTo: z.string().optional().nullable(),
  discountType: z.enum(discountTypes).optional().nullable(),
  discountValue: z.coerce.number().min(0).optional().nullable(),
  fixedPrice: z.coerce.number().min(0).optional().nullable(),
  minQuantity: z.coerce.number().positive().optional().nullable(),
  minBultos: z.coerce.number().positive().optional().nullable(),
  unitsPerBulto: z.coerce.number().positive().optional().nullable(),
  minOrderTotal: z.coerce.number().min(0).optional().nullable(),
  clientId: z.string().uuid().optional().nullable(),
  zoneId: z.string().uuid().optional().nullable(),
  categoryId: z.string().uuid().optional().nullable(),
  productId: z.string().uuid().optional().nullable(),
  variantId: z.string().uuid().optional().nullable(),
  conditions: z.record(z.any()).optional().nullable(),
  benefits: z.record(z.any()).optional().nullable(),
  items: z.array(promotionItemSchema).optional().default([]),
  tiers: z.array(promotionTierSchema).optional().default([]),
}).superRefine((data, ctx) => {
  const hasBenefit = data.discountType || data.discountValue != null || data.fixedPrice != null || (data.benefits && Object.keys(data.benefits).length > 0);
  if (data.isActive && !hasBenefit) ctx.addIssue({ code: 'custom', message: 'Promoción activa sin beneficio válido.'});
  if (data.type === 'combo' && (!data.items || data.items.length < 2)) ctx.addIssue({ code: 'custom', message: 'combo debe tener al menos 2 items.'});
  if (data.type === 'x_for_y') {
    const buy = Number(data.conditions?.buy_quantity ?? 0);
    const pay = Number(data.conditions?.pay_quantity ?? 0);
    if (!(buy > pay && pay > 0)) ctx.addIssue({ code: 'custom', message: 'x_for_y requiere buy_quantity > pay_quantity > 0.'});
  }
});

export const listPromotionsQuerySchema = z.object({
  isActive: z.coerce.boolean().optional(),
  type: z.enum(promotionTypes).optional(),
  q: z.string().optional(),
});
