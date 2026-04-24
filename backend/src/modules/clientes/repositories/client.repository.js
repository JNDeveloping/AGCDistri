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

  async list({ q, isActive, page, limit }) {
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
