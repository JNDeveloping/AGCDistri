import { pool } from '../../../database/pool.js';

export class ProductVariantRepository {
  async listByProduct(productId) {
    const { rows } = await pool.query(
      `SELECT *
       FROM product_variants
       WHERE product_id = $1
       ORDER BY name ASC`,
      [productId],
    );
    return rows;
  }

  async findById(id) {
    const { rows } = await pool.query('SELECT * FROM product_variants WHERE id = $1 LIMIT 1', [id]);
    return rows[0] ?? null;
  }

  async findByProductAndName(productId, name, ignoreId = null) {
    const values = [productId, name.trim().toLowerCase()];
    const whereIgnore = ignoreId ? 'AND id <> $3' : '';
    if (ignoreId) values.push(ignoreId);
    const { rows } = await pool.query(
      `SELECT id
       FROM product_variants
       WHERE product_id = $1
         AND LOWER(name) = $2
         ${whereIgnore}
       LIMIT 1`,
      values,
    );
    return rows[0] ?? null;
  }

  async create(payload) {
    const { rows } = await pool.query(
      `INSERT INTO product_variants (product_id, name, internal_code, barcode, price, cost, stock)
       VALUES ($1,$2,$3,$4,$5,$6,$7)
       RETURNING *`,
      [
        payload.productId,
        payload.name,
        payload.internalCode ?? null,
        payload.barcode ?? null,
        payload.price ?? null,
        payload.cost ?? null,
        payload.stock ?? null,
      ],
    );
    return rows[0];
  }

  async update(id, payload) {
    const { rows } = await pool.query(
      `UPDATE product_variants
       SET name = $2,
           internal_code = $3,
           barcode = $4,
           price = $5,
           cost = $6,
           stock = $7,
           updated_at = NOW()
       WHERE id = $1
       RETURNING *`,
      [id, payload.name, payload.internalCode ?? null, payload.barcode ?? null, payload.price ?? null, payload.cost ?? null, payload.stock ?? null],
    );
    return rows[0] ?? null;
  }

  async setActive(id, active) {
    const { rows } = await pool.query(
      `UPDATE product_variants
       SET is_active = $2,
           deactivated_at = CASE WHEN $2 THEN NULL ELSE NOW() END,
           updated_at = NOW()
       WHERE id = $1
       RETURNING *`,
      [id, active],
    );
    return rows[0] ?? null;
  }

  async remove(id) {
    const { rowCount } = await pool.query('DELETE FROM product_variants WHERE id = $1', [id]);
    return rowCount > 0;
  }

  async findProduct(productId) {
    const { rows } = await pool.query('SELECT id, name, wholesale_price, cost, stock_current FROM products WHERE id = $1 LIMIT 1', [productId]);
    return rows[0] ?? null;
  }
}

export const productVariantRepository = new ProductVariantRepository();

