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
      SELECT id, full_name, email, password_hash, role, is_active
      FROM users
      WHERE email = $1
      LIMIT 1
    `;

    const { rows } = await pool.query(query, [email.toLowerCase()]);
    return rows[0] ?? null;
  }

  async findById(id) {
    const query = `
      SELECT id, full_name, email, role, is_active, created_at
      FROM users
      WHERE id = $1
      LIMIT 1
    `;

    const { rows } = await pool.query(query, [id]);
    return rows[0] ?? null;
  }
}

export const userRepository = new UserRepository();
