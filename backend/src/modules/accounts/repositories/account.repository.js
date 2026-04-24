import { pool } from '../../../database/pool.js';

export class AccountRepository {
  async findClient(id) {
    const { rows } = await pool.query('SELECT id, business_name, current_balance, credit_limit, is_active FROM clients WHERE id = $1 LIMIT 1', [id]);
    return rows[0] ?? null;
  }

  async listMovements({ clientId, type, dateFrom, dateTo }) {
    const values = [];
    const where = [];
    if (clientId) { values.push(clientId); where.push(`am.client_id = $${values.length}`); }
    if (type) { values.push(type); where.push(`am.movement_type = $${values.length}`); }
    if (dateFrom) { values.push(dateFrom); where.push(`am.created_at::date >= $${values.length}`); }
    if (dateTo) { values.push(dateTo); where.push(`am.created_at::date <= $${values.length}`); }

    const { rows } = await pool.query(
      `SELECT am.*, c.business_name AS client_name, u.full_name AS user_name
       FROM account_movements am
       JOIN clients c ON c.id = am.client_id
       LEFT JOIN users u ON u.id = am.user_id
       ${where.length ? `WHERE ${where.join(' AND ')}` : ''}
       ORDER BY am.created_at DESC`,
      values,
    );
    return rows;
  }

  async createMovement(payload) {
    const { rows } = await pool.query(
      `INSERT INTO account_movements (
        client_id, movement_type, amount, previous_balance, new_balance,
        description, notes, user_id, reference_type, reference_id
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
      RETURNING *`,
      [
        payload.clientId,
        payload.movementType,
        payload.amount,
        payload.previousBalance,
        payload.newBalance,
        payload.description,
        payload.notes ?? null,
        payload.userId,
        payload.referenceType ?? null,
        payload.referenceId ?? null,
      ],
    );
    return rows[0];
  }

  async updateClientBalance(clientId, newBalance) {
    await pool.query('UPDATE clients SET current_balance = $2, updated_at = NOW() WHERE id = $1', [clientId, newBalance]);
  }

  async findMovementByReference({ referenceType, referenceId, movementType }) {
    const { rows } = await pool.query(
      'SELECT id FROM account_movements WHERE reference_type = $1 AND reference_id = $2 AND movement_type = $3 LIMIT 1',
      [referenceType, referenceId, movementType],
    );
    return rows[0] ?? null;
  }

  async listDebtors() {
    const { rows } = await pool.query(
      `SELECT id, business_name, current_balance, credit_limit
       FROM clients
       WHERE current_balance > 0
       ORDER BY current_balance DESC`,
    );
    return rows;
  }

  async summary() {
    const [debt, debtors, todayPayments] = await Promise.all([
      pool.query('SELECT COALESCE(SUM(current_balance),0)::numeric AS total_debt FROM clients WHERE current_balance > 0'),
      pool.query('SELECT COUNT(*)::int AS total_debtors FROM clients WHERE current_balance > 0'),
      pool.query('SELECT COALESCE(SUM(amount),0)::numeric AS total_paid_today FROM client_payments WHERE created_at::date = CURRENT_DATE AND is_annulled = FALSE'),
    ]);
    return {
      totalDebt: Number(debt.rows[0].total_debt),
      totalDebtors: debtors.rows[0].total_debtors,
      totalPaidToday: Number(todayPayments.rows[0].total_paid_today),
    };
  }

  async createPayment(payload) {
    const { rows } = await pool.query(
      `INSERT INTO client_payments (client_id, amount, payment_method, notes, user_id, reference_type, reference_id)
       VALUES ($1,$2,$3,$4,$5,$6,$7)
       RETURNING *`,
      [payload.clientId, payload.amount, payload.paymentMethod, payload.notes ?? null, payload.userId, payload.referenceType ?? null, payload.referenceId ?? null],
    );
    return rows[0];
  }

  async listPayments({ clientId, userId, method, dateFrom, dateTo }) {
    const values = [];
    const where = [];
    if (clientId) { values.push(clientId); where.push(`cp.client_id = $${values.length}`); }
    if (userId) { values.push(userId); where.push(`cp.user_id = $${values.length}`); }
    if (method) { values.push(method); where.push(`cp.payment_method = $${values.length}`); }
    if (dateFrom) { values.push(dateFrom); where.push(`cp.created_at::date >= $${values.length}`); }
    if (dateTo) { values.push(dateTo); where.push(`cp.created_at::date <= $${values.length}`); }

    const { rows } = await pool.query(
      `SELECT cp.*, c.business_name AS client_name, u.full_name AS user_name
       FROM client_payments cp
       JOIN clients c ON c.id = cp.client_id
       LEFT JOIN users u ON u.id = cp.user_id
       ${where.length ? `WHERE ${where.join(' AND ')}` : ''}
       ORDER BY cp.created_at DESC`,
      values,
    );
    return rows;
  }

  async findPaymentById(id) {
    const { rows } = await pool.query(
      `SELECT cp.*, c.business_name AS client_name, u.full_name AS user_name
       FROM client_payments cp
       JOIN clients c ON c.id = cp.client_id
       LEFT JOIN users u ON u.id = cp.user_id
       WHERE cp.id = $1 LIMIT 1`,
      [id],
    );
    return rows[0] ?? null;
  }
}

export const accountRepository = new AccountRepository();
