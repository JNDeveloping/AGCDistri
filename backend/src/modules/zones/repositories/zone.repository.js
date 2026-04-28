import { pool } from '../../../database/pool.js';

export class ZoneRepository {
  async list({ includeInactive = false } = {}) {
    const { rows } = await pool.query(
      `
      SELECT id, name, description, is_active, created_at, updated_at, deactivated_at
      FROM zones
      WHERE ($1::boolean = TRUE OR is_active = TRUE)
      ORDER BY name ASC
      `,
      [includeInactive],
    );

    return rows;
  }

  async findById(id) {
    const { rows } = await pool.query('SELECT * FROM zones WHERE id = $1 LIMIT 1', [id]);
    return rows[0] ?? null;
  }

  async findByName(name, ignoreId = null) {
    const { rows } = await pool.query(
      'SELECT id, name FROM zones WHERE LOWER(name) = LOWER($1) AND ($2::uuid IS NULL OR id <> $2) LIMIT 1',
      [name, ignoreId],
    );
    return rows[0] ?? null;
  }

  async create({ name, description }) {
    const { rows } = await pool.query(
      `
      INSERT INTO zones (name, description)
      VALUES ($1, $2)
      RETURNING id, name, description, is_active, created_at, updated_at, deactivated_at
      `,
      [name, description],
    );
    return rows[0];
  }

  async update(id, { name, description }) {
    const { rows } = await pool.query(
      `
      UPDATE zones
      SET name = COALESCE($2, name),
          description = $3,
          updated_at = NOW()
      WHERE id = $1
      RETURNING id, name, description, is_active, created_at, updated_at, deactivated_at
      `,
      [id, name, description],
    );
    return rows[0] ?? null;
  }

  async deactivate(id) {
    const { rows } = await pool.query(
      `
      UPDATE zones
      SET is_active = FALSE, deactivated_at = NOW(), updated_at = NOW()
      WHERE id = $1
      RETURNING id, name, description, is_active, created_at, updated_at, deactivated_at
      `,
      [id],
    );
    return rows[0] ?? null;
  }

  async activate(id) {
    const { rows } = await pool.query(
      `
      UPDATE zones
      SET is_active = TRUE, deactivated_at = NULL, updated_at = NOW()
      WHERE id = $1
      RETURNING id, name, description, is_active, created_at, updated_at, deactivated_at
      `,
      [id],
    );
    return rows[0] ?? null;
  }

  async countAssignedClients(id) {
    const { rows } = await pool.query('SELECT COUNT(*)::int AS total FROM clients WHERE zone_id = $1', [id]);
    return rows[0]?.total ?? 0;
  }

  async moveClients({ fromZoneId, toZoneId }) {
    const { rows } = await pool.query(
      `
      UPDATE clients
      SET zone_id = $2,
          route_zone = COALESCE((SELECT name FROM zones WHERE id = $2), route_zone),
          updated_at = NOW()
      WHERE zone_id = $1
      RETURNING id
      `,
      [fromZoneId, toZoneId],
    );

    return rows.length;
  }

  async remove(id) {
    const { rowCount } = await pool.query('DELETE FROM zones WHERE id = $1', [id]);
    return rowCount > 0;
  }

  async summary(id) {
    const { rows } = await pool.query(
      `
      SELECT
        (SELECT COUNT(*)::int FROM clients c WHERE c.zone_id = $1) AS total_clients,
        (SELECT COUNT(*)::int FROM orders o JOIN clients c ON c.id = o.client_id WHERE c.zone_id = $1) AS total_orders,
        (SELECT COUNT(*)::int FROM orders o JOIN clients c ON c.id = o.client_id WHERE c.zone_id = $1 AND o.status = 'pendiente') AS pending_orders,
        (SELECT COUNT(*)::int FROM orders o JOIN clients c ON c.id = o.client_id WHERE c.zone_id = $1 AND o.status = 'preparado') AS prepared_orders,
        (SELECT COUNT(*)::int FROM orders o JOIN clients c ON c.id = o.client_id WHERE c.zone_id = $1 AND o.status = 'entregado') AS delivered_orders,
        (SELECT COALESCE(SUM(o.total), 0)::numeric FROM orders o JOIN clients c ON c.id = o.client_id WHERE c.zone_id = $1 AND o.status <> 'cancelado') AS total_sales,
        (SELECT COALESCE(SUM(GREATEST(c.current_balance, 0)), 0)::numeric FROM clients c WHERE c.zone_id = $1) AS total_debt
      `,
      [id],
    );

    return rows[0] ?? null;
  }
}

export const zoneRepository = new ZoneRepository();
