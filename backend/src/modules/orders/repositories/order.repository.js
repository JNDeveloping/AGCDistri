import { pool } from '../../../database/pool.js';

const baseOrderSelect = `
  SELECT
    o.id,
    o.order_number,
    o.client_id,
    c.business_name AS client_name,
    c.phone AS client_phone,
    c.zone_id AS client_zone_id,
    COALESCE(z.name, c.route_zone) AS zone_name,
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
    COALESCE(oi_summary.items_count, 0)::int AS items_count,
    COALESCE(oi_summary.total_units, 0)::numeric AS total_units,
    o.stock_discounted,
    o.created_at,
    o.updated_at,
    o.canceled_at
  FROM orders o
  JOIN clients c ON c.id = o.client_id
  LEFT JOIN zones z ON z.id = c.zone_id
  JOIN users u ON u.id = o.seller_id
  LEFT JOIN users du ON du.id = o.assigned_delivery_user_id
  LEFT JOIN (
    SELECT
      order_id,
      COUNT(id)::int AS items_count,
      COALESCE(SUM(quantity), 0)::numeric AS total_units
    FROM order_items
    GROUP BY order_id
  ) oi_summary ON oi_summary.order_id = o.id
`;

export class OrderRepository {
  async list({ filters, pagination, role, userId }) {
    const values = [];
    const whereBase = [];
    const whereStatus = [];

    if (filters.clientId) {
      values.push(filters.clientId);
      whereBase.push(`o.client_id = $${values.length}`);
    }
    if (filters.sellerId) {
      values.push(filters.sellerId);
      whereBase.push(`o.seller_id = $${values.length}`);
    }
    if (filters.status) {
      values.push(filters.status);
      whereStatus.push(`o.status = $${values.length}`);
    }
    if (filters.dateFrom) {
      values.push(filters.dateFrom);
      whereBase.push(`o.order_date::date >= $${values.length}`);
    }
    if (filters.dateTo) {
      values.push(filters.dateTo);
      whereBase.push(`o.order_date::date <= $${values.length}`);
    }
    if (filters.orderNumber) {
      values.push(Number(filters.orderNumber));
      whereBase.push(`o.order_number = $${values.length}`);
    }
    if (filters.zoneId) {
      values.push(filters.zoneId);
      whereBase.push(`c.zone_id = $${values.length}`);
    }
    if (filters.paymentCondition) {
      values.push(filters.paymentCondition);
      whereBase.push(`o.payment_terms = $${values.length}`);
    }
    if (filters.search) {
      values.push(`%${filters.search}%`);
      const idx = values.length;
      whereBase.push(`(
        CAST(o.order_number AS TEXT) ILIKE $${idx}
        OR c.business_name ILIKE $${idx}
        OR COALESCE(c.phone, '') ILIKE $${idx}
        OR COALESCE(z.name, c.route_zone, '') ILIKE $${idx}
        OR EXISTS (
          SELECT 1 FROM order_items oi
          WHERE oi.order_id = o.id
            AND (
              COALESCE(oi.product_name_snapshot, oi.product_name, '') ILIKE $${idx}
              OR COALESCE(oi.variant_name_snapshot, '') ILIKE $${idx}
            )
        )
      )`);
    }
    if (filters.archived === 'archived') {
      whereBase.push('o.deleted_at IS NOT NULL');
    } else if (filters.archived !== 'all') {
      whereBase.push('o.deleted_at IS NULL');
    }

    if (role === 'vendedor') {
      values.push(userId);
      whereBase.push(`o.seller_id = $${values.length}`);
    }

    if (role === 'repartidor') {
      values.push(userId);
      whereBase.push(`o.assigned_delivery_user_id = $${values.length}`);
    }

    const whereClause = [...whereBase, ...whereStatus].length ? `WHERE ${[...whereBase, ...whereStatus].join(' AND ')}` : '';
    const sortFieldMap = {
      orderDate: 'o.order_date',
      total: 'o.total',
      client: 'c.business_name',
      zone: 'COALESCE(z.name, c.route_zone)',
      status: 'o.status',
    };
    const sortBy = sortFieldMap[filters.sortBy] ?? 'o.order_date';
    const sortDirection = filters.sortDirection === 'asc' ? 'ASC' : 'DESC';

    values.push(pagination.limit);
    values.push((pagination.page - 1) * pagination.limit);

    const dataQuery = `${baseOrderSelect} ${whereClause} ORDER BY ${sortBy} ${sortDirection}, o.order_date DESC LIMIT $${values.length - 1} OFFSET $${values.length}`;
    const countQuery = `SELECT COUNT(*)::int AS total FROM orders o JOIN clients c ON c.id = o.client_id LEFT JOIN zones z ON z.id = c.zone_id ${whereClause}`;
    const statusCountQuery = `
      SELECT o.status, COUNT(*)::int AS total
      FROM orders o
      JOIN clients c ON c.id = o.client_id
      LEFT JOIN zones z ON z.id = c.zone_id
      ${whereClause}
      GROUP BY o.status
    `;

    const [data, count, statusCounts] = await Promise.all([
      pool.query(dataQuery, values),
      pool.query(countQuery, values.slice(0, values.length - 2)),
      pool.query(statusCountQuery, values.slice(0, values.length - 2)),
    ]);

    return { rows: data.rows, total: count.rows[0].total, statusCounts: statusCounts.rows };
  }

  async findById(id) {
    const { rows } = await pool.query(`${baseOrderSelect} WHERE o.id = $1 LIMIT 1`, [id]);
    return rows[0] ?? null;
  }

  async listPendingDelivery({ zoneId, role, userId }) {
    const values = [];
    const filters = [`o.status = 'preparado'`];

    if (zoneId) {
      values.push(zoneId);
      filters.push(`c.zone_id = $${values.length}`);
    }
    if (role === 'vendedor') {
      values.push(userId);
      filters.push(`o.seller_id = $${values.length}`);
    }
    if (role === 'repartidor') {
      values.push(userId);
      filters.push(`o.assigned_delivery_user_id = $${values.length}`);
    }

    const whereClause = filters.length ? `WHERE ${filters.join(' AND ')}` : '';
    const query = `${baseOrderSelect} ${whereClause} ORDER BY o.order_date DESC`;
    const { rows } = await pool.query(query, values);
    return rows;
  }

  async listItems(orderId) {
    const { rows } = await pool.query(
      `
      SELECT id, order_id, product_id, product_variant_id, product_code, product_name, product_name_snapshot, variant_name_snapshot, quantity, unit_measure,
             unit_price, original_unit_price, promotion_id, applied_promotions, discount_type, discount_value, discount_amount, subtotal, cost, estimated_margin
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
      `SELECT id, internal_code, name, unit_measure, wholesale_price, cost, stock_current, has_variants, is_active
       FROM products
       WHERE id = ANY($1::uuid[])`,
      [ids],
    );
    return rows;
  }


  async findVariantsByIds(ids) {
    const { rows } = await pool.query(
      `SELECT pv.id, pv.product_id, pv.name, pv.price, pv.cost, pv.stock, pv.is_active
       FROM product_variants pv
       WHERE pv.id = ANY($1::uuid[])`,
      [ids],
    );
    return rows;
  }

  async listCreditNotesByOrder(orderId) {
    const { rows } = await pool.query(
      `SELECT id, number, reason, total_amount, created_at
       FROM credit_notes
       WHERE order_id = $1
       ORDER BY created_at DESC`,
      [orderId],
    );
    return rows;
  }

  async getCreditNotesSummary(orderId) {
    const { rows } = await pool.query(
      `SELECT COALESCE(SUM(total_amount), 0)::numeric AS total_credited, COUNT(*)::int AS notes_count
       FROM credit_notes
       WHERE order_id = $1`,
      [orderId],
    );
    return rows[0] ?? { total_credited: 0, notes_count: 0 };
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
          order_id, product_id, product_variant_id, product_code, product_name, product_name_snapshot, variant_name_snapshot, quantity, unit_measure,
          unit_price, original_unit_price, promotion_id, applied_promotions, discount_type, discount_value, discount_amount, subtotal, cost, estimated_margin
        ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13::jsonb,$14,$15,$16,$17,$18,$19)
        `,
        [
          orderId,
          item.productId,
          item.productVariantId,
          item.productCode,
          item.productName,
          item.productNameSnapshot,
          item.variantNameSnapshot,
          item.quantity,
          item.unitMeasure,
          item.unitPrice,
          item.originalUnitPrice ?? item.unitPrice,
          item.promotionId ?? null,
          JSON.stringify(item.appliedPromotions ?? []),
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
          order_id, product_id, product_variant_id, product_code, product_name, product_name_snapshot, variant_name_snapshot, quantity, unit_measure,
          unit_price, original_unit_price, promotion_id, applied_promotions, discount_type, discount_value, discount_amount, subtotal, cost, estimated_margin
        ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13::jsonb,$14,$15,$16,$17,$18,$19)
        `,
        [
          id,
          item.productId,
          item.productVariantId,
          item.productCode,
          item.productName,
          item.productNameSnapshot,
          item.variantNameSnapshot,
          item.quantity,
          item.unitMeasure,
          item.unitPrice,
          item.originalUnitPrice ?? item.unitPrice,
          item.promotionId ?? null,
          JSON.stringify(item.appliedPromotions ?? []),
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

  async replaceOrderPromotionApplications(orderId, applications = []) {
    await pool.query('DELETE FROM order_promotion_applications WHERE order_id = $1', [orderId]);
    for (const app of applications) {
      await pool.query(
        `INSERT INTO order_promotion_applications (order_id, promotion_id, order_item_id, discount_amount, original_amount, final_amount, application_count, metadata)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8::jsonb)`,
        [orderId, app.promotion_id, app.order_item_id ?? null, app.amount ?? 0, app.original_amount ?? null, app.final_amount ?? null, app.application_count ?? 1, JSON.stringify(app.metadata ?? {})],
      );
    }
  }

  async listOrderPromotionApplications(orderId) {
    const { rows } = await pool.query('SELECT * FROM order_promotion_applications WHERE order_id = $1 ORDER BY created_at ASC', [orderId]);
    return rows;
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

  async hasAccountOrStockMovements(id) {
    const { rows } = await pool.query(
      `SELECT
        EXISTS(SELECT 1 FROM stock_movements WHERE reference_type = 'order' AND reference_id = $1) AS has_stock,
        EXISTS(SELECT 1 FROM account_movements WHERE reference_type = 'order' AND reference_id = $1) AS has_account`,
      [id],
    );
    const row = rows[0] ?? {};
    return row.has_stock === true || row.has_account === true;
  }

  async remove(id) {
    const { rowCount } = await pool.query('UPDATE orders SET deleted_at = NOW(), updated_at = NOW() WHERE id = $1', [id]);
    return rowCount > 0;
  }

  async archive(id, userId, reason = null) {
    const { rowCount } = await pool.query(
      'UPDATE orders SET deleted_at = NOW(), deleted_by = $2, delete_reason = $3, updated_at = NOW() WHERE id = $1',
      [id, userId, reason],
    );
    return rowCount > 0;
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
