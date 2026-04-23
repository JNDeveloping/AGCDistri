import { pool } from '../../../database/pool.js';

const baseSelect = `
  SELECT
    id, internal_code, name, short_description, long_description,
    brand, category, segment, barcode, unit_measure, presentation,
    cost, wholesale_price, retail_price, margin_percentage,
    stock_current, stock_minimum, is_active, is_featured, image_url,
    tax_rate, created_at, updated_at, deactivated_at
  FROM products
`;

export class ProductRepository {
  async create(payload) {
    const query = `
      INSERT INTO products (
        internal_code, name, short_description, long_description,
        brand, category, segment, barcode, unit_measure, presentation,
        cost, wholesale_price, retail_price, margin_percentage,
        stock_current, stock_minimum, is_featured, image_url, tax_rate
      ) VALUES (
        $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,
        $11,$12,$13,$14,$15,$16,$17,$18,$19
      )
      RETURNING *
    `;

    const values = [
      payload.internalCode,
      payload.name,
      payload.shortDescription,
      payload.longDescription,
      payload.brand,
      payload.category,
      payload.segment,
      payload.barcode,
      payload.unitMeasure,
      payload.presentation,
      payload.cost,
      payload.wholesalePrice,
      payload.retailPrice,
      payload.marginPercentage,
      payload.stockCurrent,
      payload.stockMinimum,
      payload.isFeatured,
      payload.imageUrl,
      payload.taxRate,
    ];

    const { rows } = await pool.query(query, values);
    return rows[0];
  }

  async findById(id) {
    const { rows } = await pool.query(`${baseSelect} WHERE id = $1 LIMIT 1`, [id]);
    return rows[0] ?? null;
  }

  async findDuplicated({ internalCode, barcode, ignoreId = null }) {
    const query = `
      SELECT id, internal_code, barcode
      FROM products
      WHERE (internal_code = $1 OR ($2 IS NOT NULL AND barcode = $2))
      AND ($3::uuid IS NULL OR id <> $3)
      LIMIT 1
    `;

    const { rows } = await pool.query(query, [internalCode, barcode, ignoreId]);
    return rows[0] ?? null;
  }

  async list({ q, isActive, lowStock, page, limit }) {
    const offset = (page - 1) * limit;
    const filters = [];
    const values = [];

    if (q) {
      values.push(`%${q}%`);
      const idx = values.length;
      filters.push(`(
        name ILIKE $${idx} OR internal_code ILIKE $${idx} OR segment ILIKE $${idx}
        OR brand ILIKE $${idx} OR category ILIKE $${idx} OR barcode ILIKE $${idx}
      )`);
    }

    if (typeof isActive === 'boolean') {
      values.push(isActive);
      filters.push(`is_active = $${values.length}`);
    }

    if (lowStock) {
      filters.push('stock_current <= stock_minimum');
    }

    const where = filters.length ? `WHERE ${filters.join(' AND ')}` : '';
    values.push(limit, offset);

    const dataQuery = `${baseSelect} ${where} ORDER BY name ASC LIMIT $${values.length - 1} OFFSET $${values.length}`;
    const countQuery = `SELECT COUNT(*)::int AS total FROM products ${where}`;

    const [data, count] = await Promise.all([
      pool.query(dataQuery, values),
      pool.query(countQuery, values.slice(0, values.length - 2)),
    ]);

    return { rows: data.rows, total: count.rows[0].total };
  }

  async update(id, patch) {
    const dbMap = {
      internalCode: 'internal_code',
      name: 'name',
      shortDescription: 'short_description',
      longDescription: 'long_description',
      brand: 'brand',
      category: 'category',
      segment: 'segment',
      barcode: 'barcode',
      unitMeasure: 'unit_measure',
      presentation: 'presentation',
      cost: 'cost',
      wholesalePrice: 'wholesale_price',
      retailPrice: 'retail_price',
      marginPercentage: 'margin_percentage',
      stockCurrent: 'stock_current',
      stockMinimum: 'stock_minimum',
      isFeatured: 'is_featured',
      imageUrl: 'image_url',
      taxRate: 'tax_rate',
    };

    const keys = Object.keys(patch).filter((key) => dbMap[key]);
    if (!keys.length) {
      return this.findById(id);
    }

    const values = [];
    const sets = [];
    keys.forEach((key) => {
      values.push(patch[key]);
      sets.push(`${dbMap[key]} = $${values.length}`);
    });

    values.push(id);
    const query = `UPDATE products SET ${sets.join(', ')}, updated_at = NOW() WHERE id = $${values.length} RETURNING *`;
    const { rows } = await pool.query(query, values);
    return rows[0] ?? null;
  }

  async deactivate(id) {
    const query = `
      UPDATE products
      SET is_active = FALSE, deactivated_at = NOW(), updated_at = NOW()
      WHERE id = $1
      RETURNING *
    `;

    const { rows } = await pool.query(query, [id]);
    return rows[0] ?? null;
  }
}

export const productRepository = new ProductRepository();
