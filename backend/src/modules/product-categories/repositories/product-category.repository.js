import { pool } from '../../../database/pool.js';

export class ProductCategoryRepository {
  async list(includeInactive) {
    const query = `
      SELECT id, name, description, is_active, created_at, updated_at, deactivated_at
      FROM product_categories
      ${includeInactive ? '' : 'WHERE is_active = TRUE'}
      ORDER BY name ASC
    `;

    const { rows } = await pool.query(query);
    return rows;
  }

  async findById(id) {
    const { rows } = await pool.query(
      'SELECT id, name, description, is_active, created_at, updated_at, deactivated_at FROM product_categories WHERE id = $1 LIMIT 1',
      [id],
    );

    return rows[0] ?? null;
  }

  async findByName(name, ignoreId = null) {
    const query = `
      SELECT id, name FROM product_categories
      WHERE LOWER(name) = LOWER($1)
      AND ($2::uuid IS NULL OR id <> $2)
      LIMIT 1
    `;

    const { rows } = await pool.query(query, [name, ignoreId]);
    return rows[0] ?? null;
  }

  async create(payload) {
    const { rows } = await pool.query(
      'INSERT INTO product_categories (name, description) VALUES ($1, $2) RETURNING id',
      [payload.name, payload.description ?? null],
    );

    return this.findById(rows[0].id);
  }

  async update(id, patch) {
    const fields = [];
    const values = [];

    if (patch.name !== undefined) {
      values.push(patch.name);
      fields.push(`name = $${values.length}`);
    }

    if (patch.description !== undefined) {
      values.push(patch.description);
      fields.push(`description = $${values.length}`);
    }

    if (!fields.length) {
      return this.findById(id);
    }

    values.push(id);
    await pool.query(`UPDATE product_categories SET ${fields.join(', ')}, updated_at = NOW() WHERE id = $${values.length}`, values);
    return this.findById(id);
  }

  async deactivate(id) {
    await pool.query(
      'UPDATE product_categories SET is_active = FALSE, deactivated_at = NOW(), updated_at = NOW() WHERE id = $1',
      [id],
    );

    return this.findById(id);
  }

  async activate(id) {
    await pool.query(
      'UPDATE product_categories SET is_active = TRUE, deactivated_at = NULL, updated_at = NOW() WHERE id = $1',
      [id],
    );

    return this.findById(id);
  }

  async countProducts(id) {
    const { rows } = await pool.query('SELECT COUNT(*)::int AS total FROM products WHERE category_id = $1', [id]);
    return rows[0]?.total ?? 0;
  }

  async moveProducts({ fromCategoryId, toCategoryId }) {
    const { rows } = await pool.query(
      `
      UPDATE products
      SET category_id = $2,
          updated_at = NOW()
      WHERE category_id = $1
      RETURNING id
      `,
      [fromCategoryId, toCategoryId],
    );
    return rows.length;
  }

  async remove(id) {
    const { rowCount } = await pool.query('DELETE FROM product_categories WHERE id = $1', [id]);
    return rowCount > 0;
  }
}

export const productCategoryRepository = new ProductCategoryRepository();
