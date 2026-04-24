import { pool } from '../../../database/pool.js';

const baseOrderSelect = `
  SELECT
    o.id,
    o.order_number,
    o.client_id,
    c.business_name AS client_name,
    o.seller_id,
    u.full_name AS seller_name,
    o.assigned_delivery_user_id,
    du.full_name AS delivery_user_name,
    o.order_date,
    o.status,
    o.notes,
    o.payment_terms,
    o.subtotal,
    o.discount_total,
    o.tax_total,
    o.total,
    o.estimated_margin,
    o.delivery_address,
    o.estimated_delivery_date,
    o.stock_discounted,
    o.created_at,
    o.updated_at,
    o.canceled_at
  FROM orders o
  JOIN clients c ON c.id = o.client_id
  JOIN users u ON u.id = o.seller_id
  LEFT JOIN users du ON du.id = o.assigned_delivery_user_id
`;

export class OrderRepository {
  async list({ filters, pagination, role, userId }) {
    const values = [];
    const where = [];

    if (filters.clientId) {
      values.push(filters.clientId);
      where.push(`o.client_id = $${values.length}`);
    }
    if (filters.sellerId) {
      values.push(filters.sellerId);
      where.push(`o.seller_id = $${values.length}`);
    }
    if (filters.status) {
      values.push(filters.status);
      where.push(`o.status = $${values.length}`);
    }
    if (filters.dateFrom) {
      values.push(filters.dateFrom);
      where.push(`o.order_date::date >= $${values.length}`);
    }
    if (filters.dateTo) {
      values.push(filters.dateTo);
      where.push(`o.order_date::date <= $${values.length}`);
    }
    if (filters.orderNumber) {
      values.push(Number(filters.orderNumber));
      where.push(`o.order_number = $${values.length}`);
    }

    if (role === 'vendedor') {
      values.push(userId);
      where.push(`o.seller_id = $${values.length}`);
    }

    if (role === 'repartidor') {
      values.push(userId);
      where.push(`o.assigned_delivery_user_id = $${values.length}`);
    }

    const whereClause = where.length ? `WHERE ${where.join(' AND ')}` : '';

    values.push(pagination.limit);
    values.push((pagination.page - 1) * pagination.limit);

    const dataQuery = `${baseOrderSelect} ${whereClause} ORDER BY o.order_date DESC LIMIT $${values.length - 1} OFFSET $${values.length}`;
    const countQuery = `SELECT COUNT(*)::int AS total FROM orders o ${whereClause}`;

    const [data, count] = await Promise.all([
      pool.query(dataQuery, values),
      pool.query(countQuery, values.slice(0, values.length - 2)),
    ]);

    return { rows: data.rows, total: count.rows[0].total };
  }

  async findById(id) {
    const { rows } = await pool.query(`${baseOrderSelect} WHERE o.id = $1 LIMIT 1`, [id]);
    return rows[0] ?? null;
  }

  async listItems(orderId) {
    const { rows } = await pool.query(
      `
      SELECT id, order_id, product_id, product_code, product_name, quantity, unit_measure,
             unit_price, discount_type, discount_value, discount_amount, subtotal, cost, estimated_margin
      FROM order_items
      WHERE order_id = $1
      ORDER BY created_at ASC
      `,
      [orderId],
    );

    return rows;
  }

  async findProductsByIds(ids) {
    const { rows } = await pool.query(
      `SELECT id, internal_code, name, unit_measure, wholesale_price, cost, stock_current, is_active
       FROM products
       WHERE id = ANY($1::uuid[])`,
      [ids],
    );
    return rows;
  }

  async createOrder(client, payload, sellerId, computed) {
    const { rows } = await pool.query(
      `
      INSERT INTO orders (
        client_id, seller_id, order_date, status, notes, payment_terms,
        subtotal, discount_total, tax_total, total, estimated_margin,
        delivery_address, estimated_delivery_date
      ) VALUES (
        $1,$2,NOW(),'pendiente',$3,$4,$5,$6,$7,$8,$9,$10,$11
      )
      RETURNING id
      `,
      [
        payload.clientId,
        sellerId,
        payload.notes ?? null,
        payload.paymentTerms ?? null,
        computed.subtotal,
        computed.discountTotal,
        computed.taxTotal,
        computed.total,
        computed.estimatedMargin,
        payload.deliveryAddress ?? client.address_line,
        payload.estimatedDeliveryDate ?? null,
      ],
    );

    const orderId = rows[0].id;

    for (const item of computed.items) {
      await pool.query(
        `
        INSERT INTO order_items (
          order_id, product_id, product_code, product_name, quantity, unit_measure,
          unit_price, discount_type, discount_value, discount_amount, subtotal, cost, estimated_margin
        ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)
        `,
        [
          orderId,
          item.productId,
          item.productCode,
          item.productName,
          item.quantity,
          item.unitMeasure,
          item.unitPrice,
          item.discountType,
          item.discountValue,
          item.discountAmount,
          item.subtotal,
          item.cost,
          item.estimatedMargin,
        ],
      );
    }

    return orderId;
  }

  async updatePendingOrder(id, client, payload, computed) {
    await pool.query(
      `
      UPDATE orders
      SET client_id = $2,
          notes = $3,
          payment_terms = $4,
          subtotal = $5,
          discount_total = $6,
          tax_total = $7,
          total = $8,
          estimated_margin = $9,
          delivery_address = $10,
          estimated_delivery_date = $11,
          updated_at = NOW()
      WHERE id = $1
      `,
      [
        id,
        payload.clientId,
        payload.notes ?? null,
        payload.paymentTerms ?? null,
        computed.subtotal,
        computed.discountTotal,
        computed.taxTotal,
        computed.total,
        computed.estimatedMargin,
        payload.deliveryAddress ?? client.address_line,
        payload.estimatedDeliveryDate ?? null,
      ],
    );

    await pool.query('DELETE FROM order_items WHERE order_id = $1', [id]);

    for (const item of computed.items) {
      await pool.query(
        `
        INSERT INTO order_items (
          order_id, product_id, product_code, product_name, quantity, unit_measure,
          unit_price, discount_type, discount_value, discount_amount, subtotal, cost, estimated_margin
        ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)
        `,
        [
          id,
          item.productId,
          item.productCode,
          item.productName,
          item.quantity,
          item.unitMeasure,
          item.unitPrice,
          item.discountType,
          item.discountValue,
          item.discountAmount,
          item.subtotal,
          item.cost,
          item.estimatedMargin,
        ],
      );
    }
  }

  async updateStatus(id, status) {
    const { rows } = await pool.query('UPDATE orders SET status = $2, updated_at = NOW() WHERE id = $1 RETURNING id', [id, status]);
    return rows[0] ?? null;
  }

  async cancel(id) {
    const { rows } = await pool.query(
      `UPDATE orders SET status = 'cancelado', canceled_at = NOW(), updated_at = NOW() WHERE id = $1 RETURNING id`,
      [id],
    );
    return rows[0] ?? null;
  }

  async applyStockDiscount(orderId) {
    await pool.query(
      `
      UPDATE products p
      SET stock_current = p.stock_current - oi.quantity,
          updated_at = NOW()
      FROM order_items oi
      WHERE oi.order_id = $1
        AND oi.product_id = p.id
      `,
      [orderId],
    );

    await pool.query('UPDATE orders SET stock_discounted = TRUE, updated_at = NOW() WHERE id = $1', [orderId]);
  }

  async restoreStock(orderId) {
    await pool.query(
      `
      UPDATE products p
      SET stock_current = p.stock_current + oi.quantity,
          updated_at = NOW()
      FROM order_items oi
      WHERE oi.order_id = $1
        AND oi.product_id = p.id
      `,
      [orderId],
    );

    await pool.query('UPDATE orders SET stock_discounted = FALSE, updated_at = NOW() WHERE id = $1', [orderId]);
  }
}

export const orderRepository = new OrderRepository();
