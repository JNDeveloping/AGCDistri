import { pool } from '../../../database/pool.js';

const baseSelect = `
  SELECT
    p.id, p.internal_code, p.name, p.short_description, p.long_description,
    p.brand, p.barcode, p.unit_measure,
    p.cost, p.wholesale_price, p.margin_percentage,
    p.stock_current, p.stock_minimum, p.is_active, p.is_featured, p.image_url,
    p.tax_rate, p.notes, p.created_at, p.updated_at, p.deactivated_at,
    p.category_id,
    c.name AS category_name,
    c.is_active AS category_is_active
  FROM products p
  LEFT JOIN product_categories c ON c.id = p.category_id
`;

export class ProductRepository {
  async create(payload) {
    const query = `
      INSERT INTO products (
        internal_code, name, short_description, long_description,
        brand, barcode, unit_measure,
        cost, wholesale_price, margin_percentage,
        stock_current, stock_minimum, is_featured, image_url, tax_rate,
        category_id, notes
      ) VALUES (
        $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,
        $11,$12,$13,$14,$15,$16,$17
      )
      RETURNING *
    `;

    const values = [
      payload.internalCode,
      payload.name,
      payload.shortDescription,
      payload.longDescription,
      payload.brand,
      payload.barcode,
      payload.unitMeasure,
      payload.cost,
      payload.wholesalePrice,
      payload.marginPercentage,
      payload.stockCurrent,
      payload.stockMinimum,
      payload.isFeatured,
      payload.imageUrl,
      payload.taxRate,
      payload.categoryId,
      payload.notes,
    ];

    const { rows } = await pool.query(query, values);
    return this.findById(rows[0].id);
  }

  async findById(id) {
    const { rows } = await pool.query(`${baseSelect} WHERE p.id = $1 LIMIT 1`, [id]);
    return rows[0] ?? null;
  }

  async findDuplicated({ internalCode, barcode, ignoreId = null }) {
    const conditions = [];
    const values = [];

    if (internalCode) {
      values.push(internalCode);
      conditions.push(`internal_code = $${values.length}`);
    }

    if (barcode) {
      values.push(barcode);
      conditions.push(`barcode = $${values.length}`);
    }

    if (!conditions.length) {
      return null;
    }

    let query = `SELECT id, internal_code, barcode FROM products WHERE (${conditions.join(' OR ')})`;

    if (ignoreId) {
      values.push(ignoreId);
      query += ` AND id <> $${values.length}`;
    }

    query += ' LIMIT 1';

    const { rows } = await pool.query(query, values);
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
        p.name ILIKE $${idx} OR p.internal_code ILIKE $${idx} OR p.brand ILIKE $${idx}
        OR p.barcode ILIKE $${idx} OR c.name ILIKE $${idx}
      )`);
    }

    if (typeof isActive === 'boolean') {
      values.push(isActive);
      filters.push(`p.is_active = $${values.length}`);
    }

    if (lowStock) {
      filters.push('p.stock_current <= p.stock_minimum');
    }

    const where = filters.length ? `WHERE ${filters.join(' AND ')}` : '';
    values.push(limit, offset);

    const dataQuery = `${baseSelect} ${where} ORDER BY p.name ASC LIMIT $${values.length - 1} OFFSET $${values.length}`;
    const countQuery = `SELECT COUNT(*)::int AS total FROM products p LEFT JOIN product_categories c ON c.id = p.category_id ${where}`;

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
      barcode: 'barcode',
      unitMeasure: 'unit_measure',
      cost: 'cost',
      wholesalePrice: 'wholesale_price',
      marginPercentage: 'margin_percentage',
      stockCurrent: 'stock_current',
      stockMinimum: 'stock_minimum',
      isFeatured: 'is_featured',
      imageUrl: 'image_url',
      taxRate: 'tax_rate',
      categoryId: 'category_id',
      notes: 'notes',
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
    const query = `UPDATE products SET ${sets.join(', ')}, updated_at = NOW() WHERE id = $${values.length} RETURNING id`;
    const { rows } = await pool.query(query, values);
    return this.findById(rows[0].id);
  }

  async deactivate(id) {
    const query = `
      UPDATE products
      SET is_active = FALSE, deactivated_at = NOW(), updated_at = NOW()
      WHERE id = $1
      RETURNING id
    `;

    const { rows } = await pool.query(query, [id]);
    return rows[0] ? this.findById(rows[0].id) : null;
  }
}

export const productRepository = new ProductRepository();
