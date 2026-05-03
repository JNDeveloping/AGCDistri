import { pool } from '../../../database/pool.js';

let hasVariantsColumnCache;

const resolveHasVariantsSupport = async () => {
  if (typeof hasVariantsColumnCache === 'boolean') return hasVariantsColumnCache;

  const { rows } = await pool.query(
    `SELECT EXISTS (
      SELECT 1
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = 'products'
        AND column_name = 'has_variants'
    ) AS exists`,
  );

  hasVariantsColumnCache = rows[0]?.exists === true;
  return hasVariantsColumnCache;
};

const buildBaseSelect = (supportsHasVariants) => `
  SELECT
    p.id, p.internal_code, p.name, p.short_description, p.long_description,
    p.brand, p.barcode, p.unit_measure,
    p.cost, p.wholesale_price, p.margin_percentage,
    p.stock_current, p.stock_minimum, p.is_active,
    ${supportsHasVariants ? 'p.has_variants' : 'FALSE AS has_variants'},
    p.is_featured, p.image_url,
    p.tax_rate, p.notes, p.created_at, p.updated_at, p.deactivated_at,
    p.category_id,
    c.name AS category_name,
    c.is_active AS category_is_active,
    EXISTS (
      SELECT 1
      FROM promotions pr
      WHERE pr.deleted_at IS NULL
        AND pr.is_active = TRUE
        AND (pr.start_date IS NULL OR pr.start_date <= NOW())
        AND (pr.end_date IS NULL OR pr.end_date >= NOW())
        AND (
          pr.product_id = p.id
          OR (pr.category_id IS NOT NULL AND pr.category_id = p.category_id)
          OR EXISTS (
            SELECT 1 FROM promotion_items pi
            WHERE pi.promotion_id = pr.id AND (pi.product_id = p.id OR pi.category_id = p.category_id)
          )
        )
    ) AS has_active_promotion
  FROM products p
  LEFT JOIN product_categories c ON c.id = p.category_id
`;

export class ProductRepository {
  async create(payload) {
    const supportsHasVariants = await resolveHasVariantsSupport();
    const hasVariantsColumns = supportsHasVariants ? ', has_variants' : '';
    const hasVariantsValues = supportsHasVariants ? ', $13' : '';

    const query = `
      INSERT INTO products (
        internal_code, name, short_description, long_description,
        brand, barcode, unit_measure,
        cost, wholesale_price, margin_percentage,
        stock_current, stock_minimum${hasVariantsColumns}, is_featured, image_url, tax_rate,
        category_id, notes
      ) VALUES (
        $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,
        $11,$12${hasVariantsValues},$${supportsHasVariants ? '14' : '13'},$${supportsHasVariants ? '15' : '14'},$${supportsHasVariants ? '16' : '15'},$${supportsHasVariants ? '17' : '16'},$${supportsHasVariants ? '18' : '17'}
      )
      RETURNING id
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
      ...(supportsHasVariants ? [payload.hasVariants ?? false] : []),
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
    const supportsHasVariants = await resolveHasVariantsSupport();
    const baseSelect = buildBaseSelect(supportsHasVariants);
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
    const supportsHasVariants = await resolveHasVariantsSupport();
    const baseSelect = buildBaseSelect(supportsHasVariants);
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


  async autocomplete({ q, limit = 20 }) {
    const term = `%${q}%`;
    const { rows } = await pool.query(
      `
      SELECT * FROM (
        SELECT
          p.id AS product_id,
          p.name AS product_name,
          p.internal_code AS product_internal_code,
          p.barcode AS product_barcode,
          p.brand,
          p.has_variants,
          p.wholesale_price AS product_price,
          p.stock_current AS product_stock,
          NULL::numeric AS variant_price,
          NULL::numeric AS variant_stock,
          NULL::uuid AS variant_id,
          NULL::text AS variant_name,
          NULL::text AS variant_internal_code,
          NULL::text AS variant_barcode,
          c.name AS category_name,
          120 AS relevance
        FROM products p
        LEFT JOIN product_categories c ON c.id = p.category_id
        WHERE p.is_active = TRUE
          AND p.has_variants = FALSE
          AND (
            p.name ILIKE $1
            OR p.internal_code ILIKE $1
            OR COALESCE(p.barcode, '') ILIKE $1
            OR COALESCE(p.brand, '') ILIKE $1
            OR COALESCE(c.name, '') ILIKE $1
          )

        UNION ALL

        SELECT
          p.id AS product_id,
          p.name AS product_name,
          p.internal_code AS product_internal_code,
          p.barcode AS product_barcode,
          p.brand,
          p.has_variants,
          p.wholesale_price AS product_price,
          p.stock_current AS product_stock,
          pv.price AS variant_price,
          pv.stock AS variant_stock,
          pv.id AS variant_id,
          pv.name AS variant_name,
          pv.internal_code AS variant_internal_code,
          pv.barcode AS variant_barcode,
          c.name AS category_name,
          140 AS relevance
        FROM products p
        JOIN product_variants pv ON pv.product_id = p.id
        LEFT JOIN product_categories c ON c.id = p.category_id
        WHERE p.is_active = TRUE
          AND p.has_variants = TRUE
          AND pv.is_active = TRUE
          AND (
            p.name ILIKE $1
            OR p.internal_code ILIKE $1
            OR COALESCE(p.barcode, '') ILIKE $1
            OR COALESCE(p.brand, '') ILIKE $1
            OR COALESCE(c.name, '') ILIKE $1
            OR pv.name ILIKE $1
            OR COALESCE(pv.internal_code, '') ILIKE $1
            OR COALESCE(pv.barcode, '') ILIKE $1
          )
      ) q
      ORDER BY relevance DESC, product_name ASC, variant_name ASC NULLS LAST
      LIMIT $2
      `,
      [term, limit],
    );

    return rows;
  }

  async update(id, patch) {
    const supportsHasVariants = await resolveHasVariantsSupport();
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
      ...(supportsHasVariants ? { hasVariants: 'has_variants' } : {}),
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

  async listActivePromotionsByProduct(productId) {
    const { rows } = await pool.query(
      `SELECT pr.id, pr.name, pr.type, pr.start_date, pr.end_date, pr.discount_type, pr.discount_value, pr.fixed_price,
              pr.product_id, pr.variant_id, pi.variant_id AS item_variant_id
       FROM promotions pr
       LEFT JOIN promotion_items pi ON pi.promotion_id = pr.id
       WHERE pr.deleted_at IS NULL
         AND pr.is_active = TRUE
         AND (pr.start_date IS NULL OR pr.start_date <= NOW())
         AND (pr.end_date IS NULL OR pr.end_date >= NOW())
         AND (
           pr.product_id = $1
           OR EXISTS (SELECT 1 FROM promotion_items x WHERE x.promotion_id = pr.id AND x.product_id = $1)
         )
       ORDER BY pr.priority DESC, pr.created_at ASC`,
      [productId],
    );
    return rows;
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
