import { pool } from '../../../database/pool.js';

const baseDeliverySelect = `
  SELECT
    d.id,
    d.number,
    d.date,
    d.driver_id,
    u.full_name AS driver_name,
    d.status,
    d.notes,
    d.zone,
    d.total_orders,
    d.total_amount,
    d.created_by,
    d.created_at,
    d.updated_at,
    d.finished_at
  FROM deliveries d
  LEFT JOIN users u ON u.id = d.driver_id
`;

export class DeliveryRepository {
  async list({ date, status, driverId, page, limit, role, userId }) {
    const values = [];
    const where = [];

    if (date) {
      values.push(date);
      where.push(`d.date = $${values.length}`);
    }

    if (status) {
      values.push(status);
      where.push(`d.status = $${values.length}`);
    }

    if (driverId) {
      values.push(driverId);
      where.push(`d.driver_id = $${values.length}`);
    }

    if (role === 'repartidor') {
      values.push(userId);
      where.push(`d.driver_id = $${values.length}`);
    }

    const whereClause = where.length ? `WHERE ${where.join(' AND ')}` : '';

    values.push(limit);
    values.push((page - 1) * limit);

    const dataQuery = `${baseDeliverySelect} ${whereClause} ORDER BY d.date DESC, d.created_at DESC LIMIT $${values.length - 1} OFFSET $${values.length}`;
    const countQuery = `SELECT COUNT(*)::int AS total FROM deliveries d ${whereClause}`;

    const [dataResult, countResult] = await Promise.all([
      pool.query(dataQuery, values),
      pool.query(countQuery, values.slice(0, values.length - 2)),
    ]);

    return { rows: dataResult.rows, total: countResult.rows[0].total };
  }

  async create({ date, driverId, notes, zone, createdBy }) {
    const { rows } = await pool.query(
      `
      INSERT INTO deliveries (date, driver_id, notes, zone, created_by)
      VALUES (COALESCE($1::date, CURRENT_DATE), $2, $3, $4, $5)
      RETURNING id
      `,
      [date, driverId ?? null, notes ?? null, zone ?? null, createdBy],
    );

    return this.findById(rows[0].id);
  }

  async findById(id) {
    const { rows } = await pool.query(`${baseDeliverySelect} WHERE d.id = $1 LIMIT 1`, [id]);
    return rows[0] ?? null;
  }

  async listOrders(deliveryId) {
    const { rows } = await pool.query(
      `
      SELECT
        dor.id,
        dor.delivery_id,
        dor.order_id,
        dor.client_id,
        dor.status,
        dor.visit_order,
        dor.notes,
        dor.estimated_time,
        dor.not_delivered_reason,
        dor.collected_cash,
        dor.collected_amount,
        dor.delivered_at,
        o.order_number,
        o.payment_terms,
        o.total,
        c.business_name AS client_name,
        c.phone AS client_phone,
        c.address_line,
        c.city,
        c.latitude,
        c.longitude,
        c.current_balance
      FROM delivery_orders dor
      JOIN orders o ON o.id = dor.order_id
      JOIN clients c ON c.id = dor.client_id
      WHERE dor.delivery_id = $1
      ORDER BY COALESCE(dor.visit_order, 999999), c.business_name ASC
      `,
      [deliveryId],
    );

    return rows;
  }

  async assignDriver(id, driverId) {
    const { rows } = await pool.query(
      `
      UPDATE deliveries
      SET driver_id = $2, updated_at = NOW()
      WHERE id = $1
      RETURNING id
      `,
      [id, driverId],
    );

    return rows[0] ? this.findById(rows[0].id) : null;
  }

  async updateStatus(id, status) {
    const shouldFinish = status === 'finalizado';
    const { rows } = await pool.query(
      `
      UPDATE deliveries
      SET status = $2,
          updated_at = NOW(),
          finished_at = CASE WHEN $3 THEN NOW() ELSE finished_at END
      WHERE id = $1
      RETURNING id
      `,
      [id, status, shouldFinish],
    );
    return rows[0] ? this.findById(rows[0].id) : null;
  }

  async addOrders(deliveryId, orderIds) {
    const orderRows = await pool.query(
      `
      SELECT o.id, o.client_id, o.total
      FROM orders o
      WHERE o.id = ANY($1::uuid[])
      `,
      [orderIds],
    );

    for (let i = 0; i < orderRows.rows.length; i += 1) {
      const order = orderRows.rows[i];
      await pool.query(
        `
        INSERT INTO delivery_orders (delivery_id, order_id, client_id, visit_order)
        VALUES ($1, $2, $3, $4)
        ON CONFLICT (delivery_id, order_id) DO NOTHING
        `,
        [deliveryId, order.id, order.client_id, i + 1],
      );

      await pool.query(
        `
        UPDATE orders
        SET assigned_delivery_user_id = COALESCE(assigned_delivery_user_id, (SELECT driver_id FROM deliveries WHERE id = $1))
        WHERE id = $2
        `,
        [deliveryId, order.id],
      );
    }

    await this.recalculateTotals(deliveryId);
    return this.findById(deliveryId);
  }

  async recalculateTotals(deliveryId) {
    await pool.query(
      `
      UPDATE deliveries d
      SET total_orders = totals.total_orders,
          total_amount = totals.total_amount,
          updated_at = NOW()
      FROM (
        SELECT
          dor.delivery_id,
          COUNT(dor.id)::int AS total_orders,
          COALESCE(SUM(o.total), 0)::numeric(14,2) AS total_amount
        FROM delivery_orders dor
        JOIN orders o ON o.id = dor.order_id
        WHERE dor.delivery_id = $1
        GROUP BY dor.delivery_id
      ) totals
      WHERE d.id = totals.delivery_id
      `,
      [deliveryId],
    );
  }

  async findActiveDeliveryByOrder(orderId, excludeDeliveryId = null) {
    const values = [orderId];
    let extra = '';
    if (excludeDeliveryId) {
      values.push(excludeDeliveryId);
      extra = `AND d.id <> $${values.length}`;
    }

    const { rows } = await pool.query(
      `
      SELECT d.id, d.number, d.status
      FROM delivery_orders dor
      JOIN deliveries d ON d.id = dor.delivery_id
      WHERE dor.order_id = $1
        AND d.status IN ('pendiente', 'en_preparacion', 'en_reparto')
        ${extra}
      LIMIT 1
      `,
      values,
    );

    return rows[0] ?? null;
  }

  async listPendingDeliveryOrders({ zone, limit = 50 }) {
    const values = [];
    const where = ["o.status = 'preparado'"];

    if (zone) {
      values.push(zone);
      where.push(`(c.route_zone = $${values.length} OR z.name = $${values.length})`);
    }

    values.push(limit);
    const { rows } = await pool.query(
      `
      SELECT
        o.id,
        o.order_number,
        o.order_date,
        o.total,
        o.payment_terms,
        o.delivery_address,
        c.id AS client_id,
        c.business_name AS client_name,
        c.phone AS client_phone,
        c.address_line,
        c.city,
        c.route_zone,
        z.name AS zone_name,
        c.latitude,
        c.longitude
      FROM orders o
      JOIN clients c ON c.id = o.client_id
      LEFT JOIN zones z ON z.id = c.zone_id
      WHERE ${where.join(' AND ')}
        AND NOT EXISTS (
          SELECT 1
          FROM delivery_orders dor
          JOIN deliveries d ON d.id = dor.delivery_id
          WHERE dor.order_id = o.id
            AND d.status IN ('pendiente', 'en_preparacion', 'en_reparto')
        )
      ORDER BY c.route_zone NULLS LAST, c.business_name ASC
      LIMIT $${values.length}
      `,
      values,
    );

    return rows;
  }

  async updateDeliveryOrderStatus({ deliveryOrderId, status, notes, reason, collectedCash, collectedAmount }) {
    const { rows } = await pool.query(
      `
      UPDATE delivery_orders
      SET status = $2,
          notes = COALESCE($3, notes),
          not_delivered_reason = CASE WHEN $2 = 'no_entregado' THEN $4 ELSE not_delivered_reason END,
          collected_cash = COALESCE($5, collected_cash),
          collected_amount = COALESCE($6, collected_amount),
          delivered_at = CASE WHEN $2 = 'entregado' THEN NOW() ELSE delivered_at END,
          updated_at = NOW()
      WHERE id = $1
      RETURNING *
      `,
      [deliveryOrderId, status, notes ?? null, reason ?? null, collectedCash ?? null, collectedAmount ?? null],
    );
    return rows[0] ?? null;
  }

  async findDeliveryOrderById(id) {
    const { rows } = await pool.query(
      `
      SELECT dor.*, d.id AS delivery_id, d.status AS delivery_status, o.payment_terms, o.id AS order_id
      FROM delivery_orders dor
      JOIN deliveries d ON d.id = dor.delivery_id
      JOIN orders o ON o.id = dor.order_id
      WHERE dor.id = $1
      LIMIT 1
      `,
      [id],
    );
    return rows[0] ?? null;
  }

  async updateOrderStatus(orderId, status) {
    await pool.query(
      `UPDATE orders SET status = $2, updated_at = NOW() WHERE id = $1`,
      [orderId, status],
    );
  }

  async optimizeRoute(deliveryId, currentLat = null, currentLng = null) {
    const orders = await this.listOrders(deliveryId);
    const withCoords = orders.filter((item) => item.latitude != null && item.longitude != null);

    if (!withCoords.length) return orders;

    const remaining = [...withCoords];
    const result = [];
    let cursor = {
      lat: currentLat != null ? Number(currentLat) : Number(remaining[0].latitude),
      lng: currentLng != null ? Number(currentLng) : Number(remaining[0].longitude),
    };

    while (remaining.length) {
      remaining.sort((a, b) => {
        const da = (Number(a.latitude) - cursor.lat) ** 2 + (Number(a.longitude) - cursor.lng) ** 2;
        const db = (Number(b.latitude) - cursor.lat) ** 2 + (Number(b.longitude) - cursor.lng) ** 2;
        return da - db;
      });
      const next = remaining.shift();
      result.push(next);
      cursor = { lat: Number(next.latitude), lng: Number(next.longitude) };
    }

    for (let i = 0; i < result.length; i += 1) {
      await pool.query(`UPDATE delivery_orders SET visit_order = $2, updated_at = NOW() WHERE id = $1`, [result[i].id, i + 1]);
    }

    return this.listOrders(deliveryId);
  }

  async todayRoutes({ role, userId }) {
    const values = [new Date().toISOString().slice(0, 10)];
    let roleFilter = '';
    if (role === 'repartidor') {
      values.push(userId);
      roleFilter = `AND d.driver_id = $${values.length}`;
    }

    const { rows } = await pool.query(
      `
      SELECT d.id, d.number, d.date, d.status, d.driver_id, u.full_name AS driver_name, d.total_orders, d.total_amount
      FROM deliveries d
      LEFT JOIN users u ON u.id = d.driver_id
      WHERE d.date = $1
      ${roleFilter}
      ORDER BY d.created_at DESC
      `,
      values,
    );

    return rows;
  }
}
