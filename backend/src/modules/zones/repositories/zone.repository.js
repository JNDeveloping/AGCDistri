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
}

export const zoneRepository = new ZoneRepository();
