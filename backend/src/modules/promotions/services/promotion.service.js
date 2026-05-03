import { AppError } from '../../../errors/app-error.js';
import { pool } from '../../../database/pool.js';
import { promotionRepository } from '../repositories/promotion.repository.js';

export class PromotionService {
  list(filters){ return promotionRepository.list(filters); }
  async getById(id){ const row = await promotionRepository.findById(id); if(!row) throw new AppError('Promoción no encontrada.',404); return row; }
  async create(payload){
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const promo = await promotionRepository.create(payload);
      await promotionRepository.replaceItems(promo.id, payload.items ?? []);
      await promotionRepository.replaceTiers(promo.id, payload.tiers ?? []);
      await client.query('COMMIT');
      return this.getById(promo.id);
    } catch(e){ await client.query('ROLLBACK'); throw e; } finally { client.release(); }
  }
  async update(id,payload){ const exists = await promotionRepository.findById(id); if(!exists) throw new AppError('Promoción no encontrada.',404); const promo = await promotionRepository.update(id,payload); await promotionRepository.replaceItems(id,payload.items??[]); await promotionRepository.replaceTiers(id,payload.tiers??[]); return promo; }
  async remove(id){ const exists = await promotionRepository.findById(id); if(!exists) throw new AppError('Promoción no encontrada.',404); await promotionRepository.softDelete(id); return {id}; }
  async toggle(id){ const row = await promotionRepository.toggle(id); if(!row) throw new AppError('Promoción no encontrada.',404); return row; }
  async preview({ client_id = null, zone_id = null, items, date = null }) {
    const now = date ? new Date(date) : new Date();
    const promotions = await promotionRepository.listApplicablePromotions({ clientId: client_id, zoneId: zone_id, now });
    const { products, variants } = await promotionRepository.resolveOrderItemsContext(items);
    const productMap = new Map(products.map((p) => [p.id, p]));
    const variantMap = new Map(variants.map((v) => [v.id, v]));

    const lines = items.map((raw) => {
      const quantity = Number(raw.quantity);
      if (!Number.isFinite(quantity) || quantity <= 0) throw new AppError('Cantidad inválida en items.', 400);
      const unitPrice = Number(raw.unit_price);
      if (!Number.isFinite(unitPrice) || unitPrice < 0) throw new AppError('Precio unitario inválido en items.', 400);
      const product = productMap.get(raw.product_id);
      if (!product) throw new AppError(`Producto no encontrado: ${raw.product_id}`, 404);
      const variant = raw.variant_id ? variantMap.get(raw.variant_id) : null;
      const stock = raw.variant_id ? Number(variant?.stock ?? 0) : (product.has_variants === true ? 0 : Number(product.stock_current ?? 0));
      return { ...raw, quantity, unit_price: unitPrice, category_id: product.category_id, has_variants: product.has_variants === true, stock, discount_amount: 0, applied_promotions: [] };
    });

    const subtotal = lines.reduce((acc, l) => acc + l.unit_price * l.quantity, 0);
    const orderPromotions = [];
    const lineAppliedByPromo = new Set();
    for (const promo of promotions) {
      let promoDiscount = 0;
      const lineIndexes = lines.map((line, idx) => ({ line, idx })).filter(({ line }) => {
        if (line.stock <= 0 || line.quantity <= 0) return false;
        if (line.has_variants && !line.variant_id) return false;
        if (promo.variant_id && promo.variant_id !== line.variant_id) return false;
        if (!promo.variant_id && promo.product_id && promo.product_id !== line.product_id) return false;
        if (promo.category_id && promo.category_id !== line.category_id) return false;
        return true;
      });
      if (!lineIndexes.length && !['order_total_discount', 'target_discount', 'combo'].includes(promo.type)) continue;

      const applyLineDiscount = (idx, amount, description = promo.name) => {
        if (amount <= 0) return;
        const key = `${promo.id}:${idx}`;
        if (!promo.stackable && lineAppliedByPromo.has(idx)) return;
        lines[idx].discount_amount += amount;
        lines[idx].applied_promotions.push({ promotion_id: promo.id, name: description, amount });
        promoDiscount += amount;
        lineAppliedByPromo.add(idx);
        lineAppliedByPromo.add(key);
      };

      if (promo.type === 'quantity_discount' || promo.type === 'bulk_discount' || promo.type === 'stock_discount') {
        for (const { line, idx } of lineIndexes) {
          const minQ = Number(promo.min_quantity ?? 1);
          if (line.quantity < minQ) continue;
          if (promo.type === 'stock_discount' && line.stock > minQ) continue;
          const amount = promo.discount_type === 'percentage'
            ? (line.unit_price * line.quantity * Number(promo.discount_value ?? 0)) / 100
            : Number(promo.discount_value ?? 0);
          applyLineDiscount(idx, Math.max(0, amount));
        }
      } else if (promo.type === 'tiered_discount') {
        const tiers = [...(promo.tiers ?? [])].sort((a, b) => Number(b.min_quantity) - Number(a.min_quantity));
        for (const { line, idx } of lineIndexes) {
          const tier = tiers.find((t) => line.quantity >= Number(t.min_quantity));
          if (!tier) continue;
          const amount = tier.discount_type === 'percentage'
            ? (line.unit_price * line.quantity * Number(tier.discount_value ?? 0)) / 100
            : tier.discount_type === 'fixed_amount'
              ? Number(tier.discount_value ?? 0)
              : Math.max(0, (line.unit_price - Number(tier.fixed_unit_price ?? line.unit_price)) * line.quantity);
          applyLineDiscount(idx, Math.max(0, amount));
        }
      } else if (promo.type === 'x_for_y') {
        const buy = Number(promo.conditions?.buy_quantity ?? 0);
        const pay = Number(promo.conditions?.pay_quantity ?? 0);
        if (buy > pay && pay > 0) {
          for (const { line, idx } of lineIndexes) {
            const groups = Math.floor(line.quantity / buy);
            if (groups <= 0) continue;
            const freeUnits = groups * (buy - pay);
            applyLineDiscount(idx, freeUnits * line.unit_price);
          }
        }
      } else if (promo.type === 'combo') {
        const required = promo.items ?? [];
        const matched = required.every((r) => lines.some((l) => (r.variant_id ? l.variant_id === r.variant_id : r.product_id ? l.product_id === r.product_id : l.category_id === r.category_id) && l.quantity >= Number(r.required_quantity ?? 1)));
        if (matched) {
          const targetTotal = lineIndexes.reduce((acc, x) => acc + x.line.unit_price * x.line.quantity, 0);
          const comboDiscount = promo.discount_type === 'percentage' ? (targetTotal * Number(promo.discount_value ?? 0)) / 100 : Number(promo.discount_value ?? 0);
          const perLine = lineIndexes.length ? comboDiscount / lineIndexes.length : 0;
          for (const { idx } of lineIndexes) applyLineDiscount(idx, Math.max(0, perLine));
        }
      } else if (promo.type === 'order_total_discount' || promo.type === 'target_discount') {
        const currentSubtotal = lines.reduce((acc, l) => acc + l.unit_price * l.quantity - l.discount_amount, 0);
        if (currentSubtotal >= Number(promo.min_order_total ?? 0)) {
          promoDiscount += promo.discount_type === 'percentage'
            ? (currentSubtotal * Number(promo.discount_value ?? 0)) / 100
            : Number(promo.discount_value ?? 0);
        }
      }

      if (promoDiscount > 0) {
        orderPromotions.push({ promotion_id: promo.id, name: promo.name, type: promo.type, amount: Number(promoDiscount.toFixed(2)) });
      }
    }

    const discount_total = Number((lines.reduce((acc, l) => acc + l.discount_amount, 0) + orderPromotions.reduce((acc, p) => acc + p.amount, 0)).toFixed(2));
    const total = Number(Math.max(0, subtotal - discount_total).toFixed(2));
    return {
      subtotal: Number(subtotal.toFixed(2)),
      discount_total,
      total,
      items: lines.map((line) => ({
        product_id: line.product_id,
        variant_id: line.variant_id ?? null,
        quantity: line.quantity,
        original_unit_price: line.unit_price,
        final_unit_price: Number(Math.max(0, line.unit_price - (line.discount_amount / line.quantity || 0)).toFixed(2)),
        discount_amount: Number(line.discount_amount.toFixed(2)),
        applied_promotions: line.applied_promotions,
      })),
      applied_promotions: orderPromotions,
    };
  }
  async selectorsProducts(q, limit){ return promotionRepository.selectorProducts({ q, limit }); }
  async selectorsCategories(){ return promotionRepository.selectorCategories(); }
  async selectorsClients(q, limit){ return promotionRepository.selectorClients({ q, limit }); }
  async selectorsZones(q, limit){ return promotionRepository.selectorZones({ q, limit }); }
}
export const promotionService = new PromotionService();
