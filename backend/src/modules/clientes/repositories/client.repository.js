import { pool } from '../../../database/pool.js';

const baseSelect = `
  SELECT
    c.id,
    c.internal_code,
    c.business_name,
    c.phone,
    c.email,
    c.tax_id,
    c.address_line,
    c.city,
    c.province,
    c.route_zone,
    c.zone_id,
    z.name AS zone_name,
    c.notes,
    c.vat_condition,
    c.credit_limit,
    c.current_balance,
    c.latitude,
    c.longitude,
    c.is_active,
    c.created_at,
    c.updated_at,
    c.deactivated_at
  FROM clients c
  LEFT JOIN zones z ON z.id = c.zone_id
`;

export class ClientRepository {
  async create(payload) {
    const query = `
      INSERT INTO clients (
        internal_code, business_name, phone,
        email, tax_id, address_line, city, province, route_zone, zone_id,
        notes, vat_condition, credit_limit, current_balance,
        latitude, longitude
      ) VALUES (
        $1, $2, $3,
        $4, $5, $6, $7, $8, $9, $10,
        $11, $12, $13, $14,
        $15, $16
      )
      RETURNING *
    `;

    const values = [
      payload.internalCode,
      payload.businessName,
      payload.phone,
      payload.email,
      payload.taxId,
      payload.addressLine,
      payload.city,
      payload.province,
      payload.routeZone,
      payload.zoneId,
      payload.notes,
      payload.vatCondition,
      payload.creditLimit,
      payload.currentBalance ?? 0,
      payload.latitude,
      payload.longitude,
    ];

    const { rows } = await pool.query(query, values);
    return rows[0];
  }

  async findById(id) {
    const { rows } = await pool.query(`${baseSelect} WHERE c.id = $1 LIMIT 1`, [id]);
    return rows[0] ?? null;
  }

  async findByCodeOrTaxId({ internalCode, taxId, ignoreId = null }) {
    const values = [internalCode];
    const duplicateFilters = ['internal_code = $1'];

    if (taxId) {
      values.push(taxId);
      duplicateFilters.push(`tax_id = $${values.length}`);
    }

    let query = `
      SELECT id, internal_code, tax_id
      FROM clients
      WHERE (${duplicateFilters.join(' OR ')})
    `;

    if (ignoreId) {
      values.push(ignoreId);
      query += ` AND id <> $${values.length}`;
    }

    query += ' LIMIT 1';

    const { rows } = await pool.query(query, values);
    return rows[0] ?? null;
  }

  async list({ q, isActive, zoneId, page, limit }) {
    const offset = (page - 1) * limit;
    const filters = [];
    const values = [];

    if (q) {
      values.push(`%${q}%`);
      const idx = values.length;
      filters.push(`(
        c.business_name ILIKE $${idx}
        OR c.phone ILIKE $${idx}
        OR c.city ILIKE $${idx}
        OR c.internal_code ILIKE $${idx}
        OR z.name ILIKE $${idx}
      )`);
    }

    if (typeof isActive === 'boolean') {
      values.push(isActive);
      filters.push(`c.is_active = $${values.length}`);
    }
    if (zoneId) {
      values.push(zoneId);
      filters.push(`c.zone_id = $${values.length}`);
    }

    const whereClause = filters.length > 0 ? `WHERE ${filters.join(' AND ')}` : '';

    values.push(limit);
    values.push(offset);

    const dataQuery = `
      ${baseSelect}
      ${whereClause}
      ORDER BY c.business_name ASC
      LIMIT $${values.length - 1}
      OFFSET $${values.length}
    `;

    const countQuery = `SELECT COUNT(*)::int AS total FROM clients c LEFT JOIN zones z ON z.id = c.zone_id ${whereClause}`;

    const [dataResult, countResult] = await Promise.all([
      pool.query(dataQuery, values),
      pool.query(countQuery, values.slice(0, values.length - 2)),
    ]);

    return {
      rows: dataResult.rows,
      total: countResult.rows[0].total,
    };
  }


  async getPurchaseHistory(clientId, limit = 12) {
    const { rows } = await pool.query(
      `
      WITH purchase_base AS (
        SELECT
          oi.product_id,
          oi.product_variant_id,
          MAX(o.order_date)::date AS last_purchase_date,
          AVG(oi.quantity)::numeric(12,2) AS avg_quantity,
          COUNT(*)::int AS purchase_count,
          AVG(EXTRACT(DAY FROM (o.order_date - LAG(o.order_date) OVER (
            PARTITION BY oi.product_id, oi.product_variant_id
            ORDER BY o.order_date
          ))))::numeric(12,2) AS avg_days_between
        FROM order_items oi
        JOIN orders o ON o.id = oi.order_id
        WHERE o.client_id = $1
          AND o.status <> 'cancelado'
        GROUP BY oi.product_id, oi.product_variant_id
      ),
      last_price AS (
        SELECT DISTINCT ON (oi.product_id, oi.product_variant_id)
          oi.product_id,
          oi.product_variant_id,
          oi.unit_price AS last_price
        FROM order_items oi
        JOIN orders o ON o.id = oi.order_id
        WHERE o.client_id = $1
          AND o.status <> 'cancelado'
        ORDER BY oi.product_id, oi.product_variant_id, o.order_date DESC, o.created_at DESC
      )
      SELECT
        pb.product_id,
        p.name AS product_name,
        pb.product_variant_id,
        pv.name AS variant_name,
        pb.last_purchase_date,
        pb.avg_quantity,
        lp.last_price,
        pb.purchase_count,
        CASE
          WHEN pb.avg_days_between IS NULL THEN 'ocasional'
          WHEN pb.avg_days_between <= 10 THEN 'semanal'
          WHEN pb.avg_days_between <= 25 THEN 'quincenal'
          WHEN pb.avg_days_between <= 45 THEN 'mensual'
          ELSE 'esporadica'
        END AS frequency
      FROM purchase_base pb
      JOIN products p ON p.id = pb.product_id
      LEFT JOIN product_variants pv ON pv.id = pb.product_variant_id
      LEFT JOIN last_price lp ON lp.product_id = pb.product_id
        AND lp.product_variant_id IS NOT DISTINCT FROM pb.product_variant_id
      WHERE p.is_active = TRUE
      ORDER BY pb.last_purchase_date DESC, pb.purchase_count DESC
      LIMIT $2
      `,
      [clientId, limit],
    );
    return rows;
  }

  async getSuggestedProducts(clientId, limit = 20) {
    const { rows } = await pool.query(
      `
      WITH client_zone AS (
        SELECT c.zone_id, z.name AS zone_name
        FROM clients c
        LEFT JOIN zones z ON z.id = c.zone_id
        WHERE c.id = $1
      ),
      frequent AS (
        SELECT
          oi.product_id,
          oi.product_variant_id,
          100 + COUNT(*)::int AS relevance_score,
          'compra_frecuente'::text AS relevance_reason,
          AVG(oi.quantity)::numeric(12,2) AS avg_quantity,
          MAX(o.order_date)::date AS last_purchase_date,
          MAX(oi.unit_price)::numeric(12,2) AS last_price
        FROM order_items oi
        JOIN orders o ON o.id = oi.order_id
        WHERE o.client_id = $1
          AND o.status <> 'cancelado'
        GROUP BY oi.product_id, oi.product_variant_id
      ),
      stale AS (
        SELECT
          f.product_id,
          f.product_variant_id,
          90 AS relevance_score,
          'hace_tiempo_no_compra'::text AS relevance_reason,
          f.avg_quantity,
          f.last_purchase_date,
          f.last_price
        FROM frequent f
        WHERE f.last_purchase_date <= (CURRENT_DATE - INTERVAL '30 days')
      ),
      top_global AS (
        SELECT
          oi.product_id,
          oi.product_variant_id,
          70 + COUNT(*)::int AS relevance_score,
          'mas_vendido_general'::text AS relevance_reason,
          AVG(oi.quantity)::numeric(12,2) AS avg_quantity,
          MAX(o.order_date)::date AS last_purchase_date,
          MAX(oi.unit_price)::numeric(12,2) AS last_price
        FROM order_items oi
        JOIN orders o ON o.id = oi.order_id
        WHERE o.status <> 'cancelado'
        GROUP BY oi.product_id, oi.product_variant_id
        ORDER BY COUNT(*) DESC
        LIMIT 40
      ),
      top_zone AS (
        SELECT
          oi.product_id,
          oi.product_variant_id,
          80 + COUNT(*)::int AS relevance_score,
          'mas_vendido_zona'::text AS relevance_reason,
          AVG(oi.quantity)::numeric(12,2) AS avg_quantity,
          MAX(o.order_date)::date AS last_purchase_date,
          MAX(oi.unit_price)::numeric(12,2) AS last_price
        FROM order_items oi
        JOIN orders o ON o.id = oi.order_id
        JOIN clients c ON c.id = o.client_id
        JOIN client_zone cz ON cz.zone_id = c.zone_id
        WHERE o.status <> 'cancelado'
        GROUP BY oi.product_id, oi.product_variant_id
        ORDER BY COUNT(*) DESC
        LIMIT 30
      ),
      merged AS (
        SELECT * FROM frequent
        UNION ALL
        SELECT * FROM stale
        UNION ALL
        SELECT * FROM top_global
        UNION ALL
        SELECT * FROM top_zone
      ),
      ranked AS (
        SELECT
          m.product_id,
          m.product_variant_id,
          MAX(m.relevance_score)::int AS relevance_score,
          (ARRAY_AGG(m.relevance_reason ORDER BY m.relevance_score DESC))[1] AS relevance_reason,
          MAX(m.avg_quantity) AS avg_quantity,
          MAX(m.last_purchase_date) AS last_purchase_date,
          MAX(m.last_price) AS last_price
        FROM merged m
        GROUP BY m.product_id, m.product_variant_id
      )
      SELECT
        r.product_id,
        p.name AS product_name,
        r.product_variant_id,
        pv.name AS variant_name,
        p.has_variants,
        COALESCE(pv.stock, p.stock_current, 0)::numeric AS stock_available,
        COALESCE(pv.price, p.wholesale_price, 0)::numeric AS current_price,
        r.last_price,
        r.avg_quantity,
        r.relevance_reason,
        r.relevance_score,
        cz.zone_name
      FROM ranked r
      JOIN products p ON p.id = r.product_id
      LEFT JOIN product_variants pv ON pv.id = r.product_variant_id
      LEFT JOIN client_zone cz ON TRUE
      WHERE p.is_active = TRUE
        AND (r.product_variant_id IS NULL OR pv.is_active = TRUE)
        AND COALESCE(pv.stock, p.stock_current, 0) > 0
      ORDER BY r.relevance_score DESC, p.name ASC
      LIMIT $2
      `,
      [clientId, limit],
    );

    return rows;
  }

  async getLastOrder(clientId) {
    const { rows } = await pool.query(
      `
      SELECT id, order_number, order_date, total, payment_terms
      FROM orders
      WHERE client_id = $1
        AND status <> 'cancelado'
      ORDER BY order_date DESC, created_at DESC
      LIMIT 1
      `,
      [clientId],
    );

    return rows[0] ?? null;
  }

  async getLastOrderItems(orderId) {
    const { rows } = await pool.query(
      `
      SELECT
        oi.product_id,
        p.name AS product_name,
        oi.product_variant_id,
        pv.name AS variant_name,
        oi.quantity,
        oi.unit_price,
        p.has_variants,
        COALESCE(pv.price, p.wholesale_price, 0)::numeric AS current_price,
        COALESCE(pv.stock, p.stock_current, 0)::numeric AS stock_available
      FROM order_items oi
      JOIN products p ON p.id = oi.product_id
      LEFT JOIN product_variants pv ON pv.id = oi.product_variant_id
      WHERE oi.order_id = $1
        AND p.is_active = TRUE
        AND (oi.product_variant_id IS NULL OR pv.is_active = TRUE)
      ORDER BY oi.created_at ASC
      `,
      [orderId],
    );

    return rows;
  }

  async update(id, patch) {
    const keys = Object.keys(patch);
    if (keys.length === 0) {
      return this.findById(id);
    }

    const dbMap = {
      internalCode: 'internal_code',
      businessName: 'business_name',
      phone: 'phone',
      email: 'email',
      taxId: 'tax_id',
      addressLine: 'address_line',
      city: 'city',
      province: 'province',
      routeZone: 'route_zone',
      zoneId: 'zone_id',
      notes: 'notes',
      vatCondition: 'vat_condition',
      creditLimit: 'credit_limit',
      currentBalance: 'current_balance',
      latitude: 'latitude',
      longitude: 'longitude',
    };

    const sets = [];
    const values = [];

    keys.forEach((key) => {
      if (dbMap[key]) {
        values.push(patch[key]);
        sets.push(`${dbMap[key]} = $${values.length}`);
      }
    });

    values.push(id);

    const query = `
      UPDATE clients
      SET ${sets.join(', ')}, updated_at = NOW()
      WHERE id = $${values.length}
      RETURNING *
    `;

    const { rows } = await pool.query(query, values);
    return rows[0] ?? null;
  }

  async deactivate(id) {
    const query = `
      UPDATE clients
      SET is_active = FALSE, deactivated_at = NOW(), updated_at = NOW()
      WHERE id = $1
      RETURNING *
    `;

    const { rows } = await pool.query(query, [id]);
    return rows[0] ?? null;
  }

  async activate(id) {
    const query = `
      UPDATE clients
      SET is_active = TRUE, deactivated_at = NULL, updated_at = NOW()
      WHERE id = $1
      RETURNING *
    `;

    const { rows } = await pool.query(query, [id]);
    return rows[0] ?? null;
  }

  async hasAssociatedMovements(id) {
    const query = `
      WITH candidate_tables AS (
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public'
          AND table_name IN ('orders', 'client_orders', 'current_account_entries', 'client_movements')
      )
      SELECT EXISTS (
        SELECT 1 FROM candidate_tables WHERE table_name = 'orders'
      ) AS has_orders_table,
      EXISTS (
        SELECT 1 FROM candidate_tables WHERE table_name = 'client_orders'
      ) AS has_client_orders_table,
      EXISTS (
        SELECT 1 FROM candidate_tables WHERE table_name = 'current_account_entries'
      ) AS has_account_entries_table,
      EXISTS (
        SELECT 1 FROM candidate_tables WHERE table_name = 'client_movements'
      ) AS has_movements_table
    `;

    const { rows } = await pool.query(query);
    const tables = rows[0] ?? {};
    let hasAssociations = false;

    if (tables.has_orders_table) {
      const { rows: orderRows } = await pool.query('SELECT 1 FROM orders WHERE client_id = $1 LIMIT 1', [id]);
      hasAssociations = hasAssociations || orderRows.length > 0;
    }

    if (tables.has_client_orders_table) {
      const { rows: orderRows } = await pool.query('SELECT 1 FROM client_orders WHERE client_id = $1 LIMIT 1', [id]);
      hasAssociations = hasAssociations || orderRows.length > 0;
    }

    if (tables.has_account_entries_table) {
      const { rows: accountRows } = await pool.query(
        'SELECT 1 FROM current_account_entries WHERE client_id = $1 LIMIT 1',
        [id],
      );
      hasAssociations = hasAssociations || accountRows.length > 0;
    }

    if (tables.has_movements_table) {
      const { rows: movementRows } = await pool.query('SELECT 1 FROM client_movements WHERE client_id = $1 LIMIT 1', [id]);
      hasAssociations = hasAssociations || movementRows.length > 0;
    }

    if (hasAssociations) {
      return true;
    }

    const row = await this.findById(id);
    return row ? Number(row.current_balance ?? 0) > 0 : false;
  }

  async remove(id) {
    const query = 'DELETE FROM clients WHERE id = $1 RETURNING id';
    const { rows } = await pool.query(query, [id]);
    return rows[0] ?? null;
  }
}

export const clientRepository = new ClientRepository();
