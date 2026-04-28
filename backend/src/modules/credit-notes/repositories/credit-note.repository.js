import { pool } from '../../../database/pool.js';

export class CreditNoteRepository {
  async list({ orderId, clientId }) {
    const values = [];
    const where = [];
    if (orderId) { values.push(orderId); where.push(`cn.order_id = $${values.length}`); }
    if (clientId) { values.push(clientId); where.push(`cn.client_id = $${values.length}`); }

    const { rows } = await pool.query(
      `SELECT cn.*, c.business_name AS client_name, u.full_name AS user_name
       FROM credit_notes cn
       JOIN clients c ON c.id = cn.client_id
       JOIN users u ON u.id = cn.user_id
       ${where.length ? `WHERE ${where.join(' AND ')}` : ''}
       ORDER BY cn.created_at DESC`,
      values,
    );
    return rows;
  }

  async findById(id) {
    const { rows } = await pool.query(
      `SELECT cn.*, c.business_name AS client_name, u.full_name AS user_name
       FROM credit_notes cn
       JOIN clients c ON c.id = cn.client_id
       JOIN users u ON u.id = cn.user_id
       WHERE cn.id = $1
       LIMIT 1`,
      [id],
    );
    return rows[0] ?? null;
  }

  async listItems(creditNoteId) {
    const { rows } = await pool.query(
      `SELECT *
       FROM credit_note_items
       WHERE credit_note_id = $1
       ORDER BY created_at ASC`,
      [creditNoteId],
    );
    return rows;
  }

  async findOrder(orderId) {
    const { rows } = await pool.query(
      `SELECT id, order_number, client_id, payment_terms, status
       FROM orders
       WHERE id = $1
       LIMIT 1`,
      [orderId],
    );
    return rows[0] ?? null;
  }

  async listOrderItems(orderId) {
    const { rows } = await pool.query(
      `SELECT id, product_id, product_name, quantity, unit_price, subtotal
       FROM order_items
       WHERE order_id = $1`,
      [orderId],
    );
    return rows;
  }

  async getCreditedByProduct(orderId) {
    const { rows } = await pool.query(
      `SELECT cni.product_id, COALESCE(SUM(cni.quantity), 0)::numeric AS credited_quantity
       FROM credit_note_items cni
       JOIN credit_notes cn ON cn.id = cni.credit_note_id
       WHERE cn.order_id = $1
       GROUP BY cni.product_id`,
      [orderId],
    );
    return rows;
  }

  async createWithItems(payload) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      const nextNumberQuery = await client.query('SELECT COALESCE(MAX(number), 0) + 1 AS next_number FROM credit_notes');
      const number = Number(nextNumberQuery.rows[0].next_number);

      const { rows: noteRows } = await client.query(
        `INSERT INTO credit_notes (number, order_id, client_id, user_id, reason, notes, total_amount, affects_stock, affects_account)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
         RETURNING *`,
        [
          number,
          payload.orderId,
          payload.clientId,
          payload.userId,
          payload.reason,
          payload.notes ?? null,
          payload.totalAmount,
          payload.affectsStock,
          payload.affectsAccount,
        ],
      );
      const note = noteRows[0];

      for (const item of payload.items) {
        await client.query(
          `INSERT INTO credit_note_items (
            credit_note_id, product_id, product_name_snapshot, quantity, unit_price, subtotal, return_to_stock, reason
          ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8)`,
          [
            note.id,
            item.productId,
            item.productNameSnapshot,
            item.quantity,
            item.unitPrice,
            item.subtotal,
            item.returnToStock,
            item.reason ?? null,
          ],
        );
      }

      await client.query('COMMIT');
      return note;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }
}

export const creditNoteRepository = new CreditNoteRepository();

