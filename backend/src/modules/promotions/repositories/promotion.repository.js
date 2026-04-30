import { pool } from '../../../database/pool.js';

export class PromotionRepository {
  async list(filters = {}) {
    const values = [];
    const where = ['deleted_at IS NULL'];
    if (filters.isActive != null) { values.push(filters.isActive); where.push(`is_active = $${values.length}`); }
    if (filters.type) { values.push(filters.type); where.push(`type = $${values.length}`); }
    if (filters.q) { values.push(`%${filters.q}%`); where.push(`(name ILIKE $${values.length} OR COALESCE(description,'') ILIKE $${values.length})`); }
    const { rows } = await pool.query(`SELECT * FROM promotions WHERE ${where.join(' AND ')} ORDER BY priority DESC, created_at DESC`, values);
    return rows;
  }
  async findById(id) { const { rows } = await pool.query('SELECT * FROM promotions WHERE id = $1 AND deleted_at IS NULL LIMIT 1',[id]); return rows[0] ?? null; }
  async create(data) {
    const { rows } = await pool.query(`INSERT INTO promotions (name,description,type,is_active,start_date,end_date,priority,stackable,applies_to,discount_type,discount_value,fixed_price,min_quantity,min_bultos,units_per_bulto,min_order_total,client_id,zone_id,category_id,product_id,variant_id,conditions,benefits)
    VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23) RETURNING *`,
    [data.name,data.description??null,data.type,data.isActive??true,data.startDate??null,data.endDate??null,data.priority??0,data.stackable??false,data.appliesTo??null,data.discountType??null,data.discountValue??null,data.fixedPrice??null,data.minQuantity??null,data.minBultos??null,data.unitsPerBulto??null,data.minOrderTotal??null,data.clientId??null,data.zoneId??null,data.categoryId??null,data.productId??null,data.variantId??null,data.conditions??null,data.benefits??null]);
    return rows[0];
  }
  async update(id,data){
    const { rows } = await pool.query(`UPDATE promotions SET name=$2,description=$3,type=$4,is_active=$5,start_date=$6,end_date=$7,priority=$8,stackable=$9,applies_to=$10,discount_type=$11,discount_value=$12,fixed_price=$13,min_quantity=$14,min_bultos=$15,units_per_bulto=$16,min_order_total=$17,client_id=$18,zone_id=$19,category_id=$20,product_id=$21,variant_id=$22,conditions=$23,benefits=$24,updated_at=NOW() WHERE id=$1 AND deleted_at IS NULL RETURNING *`,
    [id,data.name,data.description??null,data.type,data.isActive??true,data.startDate??null,data.endDate??null,data.priority??0,data.stackable??false,data.appliesTo??null,data.discountType??null,data.discountValue??null,data.fixedPrice??null,data.minQuantity??null,data.minBultos??null,data.unitsPerBulto??null,data.minOrderTotal??null,data.clientId??null,data.zoneId??null,data.categoryId??null,data.productId??null,data.variantId??null,data.conditions??null,data.benefits??null]);
    return rows[0] ?? null;
  }
  async replaceItems(promotionId, items){ await pool.query('DELETE FROM promotion_items WHERE promotion_id=$1',[promotionId]); for (const item of items){ await pool.query('INSERT INTO promotion_items (promotion_id,product_id,variant_id,category_id,required_quantity,units_per_bulto) VALUES ($1,$2,$3,$4,$5,$6)',[promotionId,item.productId??null,item.variantId??null,item.categoryId??null,item.requiredQuantity??1,item.unitsPerBulto??null]); }}
  async replaceTiers(promotionId, tiers){ await pool.query('DELETE FROM promotion_tiers WHERE promotion_id=$1',[promotionId]); for (const t of tiers){ await pool.query('INSERT INTO promotion_tiers (promotion_id,min_quantity,discount_type,discount_value,fixed_unit_price) VALUES ($1,$2,$3,$4,$5)',[promotionId,t.minQuantity,t.discountType,t.discountValue??null,t.fixedUnitPrice??null]); }}
  async softDelete(id){ await pool.query('UPDATE promotions SET deleted_at=NOW(), updated_at=NOW() WHERE id=$1',[id]); }
  async toggle(id){ const { rows } = await pool.query('UPDATE promotions SET is_active = NOT is_active, updated_at=NOW() WHERE id=$1 AND deleted_at IS NULL RETURNING *',[id]); return rows[0] ?? null; }
}

export const promotionRepository = new PromotionRepository();
