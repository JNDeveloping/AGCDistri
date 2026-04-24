import { pool } from '../../../database/pool.js';

export class StockRepository {
  async listStock({ q, lowStock, outOfStock }) {
    const values = [];
    const where = ['p.is_active = TRUE'];
    if (q) {
      values.push(`%${q}%`);
      where.push(`(p.name ILIKE $${values.length} OR p.internal_code ILIKE $${values.length} OR COALESCE(p.barcode, '') ILIKE $${values.length})`);
    }
    if (lowStock) where.push('p.stock_current <= p.stock_minimum');
    if (outOfStock) where.push('p.stock_current <= 0');

    const { rows } = await pool.query(
      `SELECT p.id, p.internal_code, p.barcode, p.name, p.stock_current, p.stock_minimum, pc.name AS category_name
       FROM products p
       LEFT JOIN product_categories pc ON pc.id = p.category_id
       WHERE ${where.join(' AND ')}
       ORDER BY p.name ASC`,
      values,
    );
    return rows;
  }

  async findProduct(productId) {
    const { rows } = await pool.query(
      `SELECT id, internal_code, barcode, name, stock_current, stock_minimum, is_active
       FROM products WHERE id = $1 LIMIT 1`,
      [productId],
    );
    return rows[0] ?? null;
  }

  async updateStock(productId, newStock) {
    await pool.query('UPDATE products SET stock_current = $2, updated_at = NOW() WHERE id = $1', [productId, newStock]);
  }

  async insertMovement(movement) {
    const { rows } = await pool.query(
      `INSERT INTO stock_movements (
        product_id, movement_type, quantity, previous_stock, new_stock, reason, notes,
        user_id, reference_type, reference_id, source_location, destination_location
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)
      RETURNING *`,
      [
        movement.productId,
        movement.movementType,
        movement.quantity,
        movement.previousStock,
        movement.newStock,
        movement.reason,
        movement.notes ?? null,
        movement.userId,
        movement.referenceType ?? null,
        movement.referenceId ?? null,
        movement.sourceLocation ?? null,
        movement.destinationLocation ?? null,
      ],
    );
    return rows[0];
  }

  async listMovements({ productId, type, userId, dateFrom, dateTo }) {
    const values = [];
    const where = [];
    if (productId) { values.push(productId); where.push(`sm.product_id = $${values.length}`); }
    if (type) { values.push(type); where.push(`sm.movement_type = $${values.length}`); }
    if (userId) { values.push(userId); where.push(`sm.user_id = $${values.length}`); }
    if (dateFrom) { values.push(dateFrom); where.push(`sm.created_at::date >= $${values.length}`); }
    if (dateTo) { values.push(dateTo); where.push(`sm.created_at::date <= $${values.length}`); }

    const { rows } = await pool.query(
      `SELECT sm.*, p.name AS product_name, p.internal_code, u.full_name AS user_name
       FROM stock_movements sm
       JOIN products p ON p.id = sm.product_id
       LEFT JOIN users u ON u.id = sm.user_id
       ${where.length ? `WHERE ${where.join(' AND ')}` : ''}
       ORDER BY sm.created_at DESC`,
      values,
    );
    return rows;
  }

  async findMovementByReference({ referenceType, referenceId, productId, movementType }) {
    const { rows } = await pool.query(
      `SELECT id FROM stock_movements
       WHERE reference_type = $1 AND reference_id = $2 AND product_id = $3 AND movement_type = $4
       LIMIT 1`,
      [referenceType, referenceId, productId, movementType],
    );
    return rows[0] ?? null;
  }
}

export const stockRepository = new StockRepository();
