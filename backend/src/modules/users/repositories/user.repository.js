import { pool } from '../../../database/pool.js';

export class UserRepository {
  async create({ fullName, email, passwordHash, role }) {
    const query = `
      INSERT INTO users (full_name, email, password_hash, role)
      VALUES ($1, $2, $3, $4)
      RETURNING id, full_name, email, role, is_active, created_at
    `;

    const values = [fullName, email.toLowerCase(), passwordHash, role];
    const { rows } = await pool.query(query, values);
    return rows[0];
  }

  async findByEmail(email) {
    const query = `
      SELECT id, full_name, email, password_hash, role, is_active, is_deleted, deleted_at
      FROM users
      WHERE email = $1 AND is_deleted = FALSE
      LIMIT 1
    `;

    const { rows } = await pool.query(query, [email.toLowerCase()]);
    return rows[0] ?? null;
  }

  async findById(id) {
    const query = `
      SELECT id, full_name, email, role, is_active, is_deleted, deleted_at, created_at
      FROM users
      WHERE id = $1
      LIMIT 1
    `;

    const { rows } = await pool.query(query, [id]);
    return rows[0] ?? null;
  }


  async findByIdentifier(identifier) {
    const normalized = String(identifier ?? '').trim().toLowerCase();
    const query = `
      SELECT id, full_name, email, password_hash, role, is_active, is_deleted, deleted_at
      FROM users
      WHERE is_deleted = FALSE
        AND (
          email = $1
          OR split_part(email, '@', 1) = $1
        )
      LIMIT 1
    `;

    const { rows } = await pool.query(query, [normalized]);
    return rows[0] ?? null;
  }

  async list() {
    const query = `
      SELECT id, full_name, email, role, is_active, is_deleted, deleted_at, created_at, updated_at
      FROM users
      WHERE is_deleted = FALSE
      ORDER BY created_at DESC
    `;

    const { rows } = await pool.query(query);
    return rows;
  }

  async update(id, patch) {
    const dbMap = {
      fullName: 'full_name',
      email: 'email',
      role: 'role',
      passwordHash: 'password_hash',
    };

    const keys = Object.keys(patch).filter((key) => dbMap[key] && patch[key] !== undefined);
    if (!keys.length) {
      return this.findById(id);
    }

    const sets = [];
    const values = [];
    keys.forEach((key) => {
      values.push(key === 'email' ? String(patch[key]).toLowerCase() : patch[key]);
      sets.push(`${dbMap[key]} = $${values.length}`);
    });

    values.push(id);
    const query = `
      UPDATE users
      SET ${sets.join(', ')}, updated_at = NOW()
      WHERE id = $${values.length}
      RETURNING id, full_name, email, role, is_active, is_deleted, deleted_at, created_at, updated_at
    `;

    const { rows } = await pool.query(query, values);
    return rows[0] ?? null;
  }

  async deactivate(id) {
    const query = `
      UPDATE users
      SET is_active = FALSE, updated_at = NOW()
      WHERE id = $1
      RETURNING id, full_name, email, role, is_active, is_deleted, deleted_at, created_at, updated_at
    `;

    const { rows } = await pool.query(query, [id]);
    return rows[0] ?? null;
  }

  async activate(id) {
    const query = `
      UPDATE users
      SET is_active = TRUE, updated_at = NOW()
      WHERE id = $1
      RETURNING id, full_name, email, role, is_active, is_deleted, deleted_at, created_at, updated_at
    `;

    const { rows } = await pool.query(query, [id]);
    return rows[0] ?? null;
  }

  async hasAssociatedMovements(id) {
    const query = `
      SELECT
        EXISTS(SELECT 1 FROM orders WHERE seller_id = $1 OR assigned_delivery_user_id = $1) AS has_orders,
        EXISTS(SELECT 1 FROM audit_logs WHERE user_id = $1) AS has_audit
    `;
    const { rows } = await pool.query(query, [id]);
    const row = rows[0] ?? {};
    return row.has_orders === true || row.has_audit === true;
  }

  async remove(id) {
    const { rowCount } = await pool.query(
      `UPDATE users
       SET is_deleted = TRUE,
           is_active = FALSE,
           deleted_at = NOW(),
           updated_at = NOW()
       WHERE id = $1`,
      [id],
    );
    return rowCount > 0;
  }
}

export const userRepository = new UserRepository();
