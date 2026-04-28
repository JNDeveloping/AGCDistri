import { AppError } from '../../../errors/app-error.js';
import { pool } from '../../../database/pool.js';

const toNum = (value) => Number(value ?? 0);

const addDateFilters = (filters, values, { dateFrom, dateTo, period }, column = 'o.order_date') => {
  if (period === 'today') {
    filters.push(`${column}::date = CURRENT_DATE`);
    return;
  }
  if (period === 'week') {
    filters.push(`${column}::date >= date_trunc('week', CURRENT_DATE)::date`);
    return;
  }
  if (period === 'month') {
    filters.push(`${column}::date >= date_trunc('month', CURRENT_DATE)::date`);
    return;
  }
  if (dateFrom) {
    values.push(dateFrom);
    filters.push(`${column}::date >= $${values.length}`);
  }
  if (dateTo) {
    values.push(dateTo);
    filters.push(`${column}::date <= $${values.length}`);
  }
};

const buildOrderFilters = (query, user) => {
  const filters = ["o.status <> 'cancelado'"];
  const values = [];

  addDateFilters(filters, values, query, 'o.order_date');

  if (query.clientId) {
    values.push(query.clientId);
    filters.push(`o.client_id = $${values.length}`);
  }

  const effectiveSellerId = user.role === 'vendedor' ? user.sub : query.sellerId;
  if (effectiveSellerId) {
    values.push(effectiveSellerId);
    filters.push(`o.seller_id = $${values.length}`);
  }

  if (query.paymentTerms) {
    values.push(query.paymentTerms);
    filters.push(`o.payment_terms = $${values.length}`);
  }

  if (query.zoneId) {
    values.push(query.zoneId);
    filters.push(`c.zone_id = $${values.length}`);
  } else if (query.zone) {
    values.push(query.zone.toLowerCase());
    filters.push(`LOWER(COALESCE(z.name, c.route_zone, '')) = $${values.length}`);
  }

  return { where: filters.length ? `WHERE ${filters.join(' AND ')}` : '', values };
};

const buildItemExtraFilters = (query, values) => {
  const filters = [];
  if (query.productId) {
    values.push(query.productId);
    filters.push(`oi.product_id = $${values.length}`);
  }
  if (query.category) {
    values.push(query.category.toLowerCase());
    filters.push(`LOWER(COALESCE(pc.name, p.category, '')) = $${values.length}`);
  }
  return filters;
};

export class ReportService {
  ensureAccess(user) {
    if (user.role === 'admin' || user.role === 'vendedor') return;
    throw new AppError('No autorizado para acceder a reportes.', 403);
  }

  async getSummary(query, user) {
    this.ensureAccess(user);

    const todaySalesQ = await pool.query("SELECT COALESCE(SUM(total),0)::numeric AS total FROM orders WHERE status <> 'cancelado' AND order_date::date = CURRENT_DATE");
    const monthSalesQ = await pool.query("SELECT COALESCE(SUM(total),0)::numeric AS total FROM orders WHERE status <> 'cancelado' AND order_date::date >= date_trunc('month', CURRENT_DATE)::date");

    const { where, values } = buildOrderFilters(query, user);
    const metricsSql = `
      SELECT
        COALESCE(SUM(o.total),0)::numeric AS total_sales,
        COALESCE(SUM(o.estimated_margin),0)::numeric AS estimated_profit,
        COUNT(*)::int AS orders_count,
        COALESCE(AVG(o.total),0)::numeric AS avg_ticket,
        COALESCE(SUM(oi.quantity),0)::numeric AS sold_units,
        COUNT(DISTINCT o.client_id)::int AS active_clients
      FROM orders o
      JOIN clients c ON c.id = o.client_id
      LEFT JOIN zones z ON z.id = c.zone_id
      LEFT JOIN order_items oi ON oi.order_id = o.id
      ${where}
    `;
    const metrics = (await pool.query(metricsSql, values)).rows[0];

    const debtors = await pool.query('SELECT COUNT(*)::int AS count, COALESCE(SUM(current_balance),0)::numeric AS total FROM clients WHERE current_balance > 0');
    const payments = await pool.query(`
      SELECT COALESCE(SUM(amount),0)::numeric AS total
      FROM client_payments
      WHERE is_annulled = FALSE
        AND created_at::date = CURRENT_DATE
    `);
    const lowStock = await pool.query('SELECT COUNT(*)::int AS total FROM products WHERE is_active = TRUE AND stock_current <= stock_minimum');

    return {
      salesToday: toNum(todaySalesQ.rows[0].total),
      salesMonth: toNum(monthSalesQ.rows[0].total),
      estimatedProfit: toNum(metrics.estimated_profit),
      ordersCount: Number(metrics.orders_count ?? 0),
      avgTicket: toNum(metrics.avg_ticket),
      debtorsCount: Number(debtors.rows[0].count ?? 0),
      totalDebt: toNum(debtors.rows[0].total),
      paymentsToday: toNum(payments.rows[0].total),
      soldUnits: toNum(metrics.sold_units),
      lowStockProducts: Number(lowStock.rows[0].total ?? 0),
      activeClients: Number(metrics.active_clients ?? 0),
    };
  }

  async getSales(query, user) {
    this.ensureAccess(user);
    const { where, values } = buildOrderFilters(query, user);

    const totals = await pool.query(`
      SELECT
        COALESCE(SUM(o.total),0)::numeric AS total_sales,
        COUNT(*)::int AS orders_count,
        COALESCE(AVG(o.total),0)::numeric AS avg_ticket
      FROM orders o
      JOIN clients c ON c.id = o.client_id
      LEFT JOIN zones z ON z.id = c.zone_id
      ${where}
    `, values);

    const series = await pool.query(`
      SELECT o.order_date::date AS day,
             COALESCE(SUM(o.total),0)::numeric AS total,
             COUNT(*)::int AS orders
      FROM orders o
      JOIN clients c ON c.id = o.client_id
      LEFT JOIN zones z ON z.id = c.zone_id
      ${where}
      GROUP BY o.order_date::date
      ORDER BY o.order_date::date ASC
    `, values);

    const byZone = await pool.query(`
      SELECT COALESCE(z.name, c.route_zone, 'Sin zona') AS zone,
             COALESCE(SUM(o.total),0)::numeric AS sales,
             COUNT(*)::int AS orders
      FROM orders o
      JOIN clients c ON c.id = o.client_id
      LEFT JOIN zones z ON z.id = c.zone_id
      ${where}
      GROUP BY COALESCE(z.name, c.route_zone, 'Sin zona')
      ORDER BY sales DESC
    `, values);

    const bySeller = await pool.query(`
      SELECT u.id AS seller_id, u.full_name AS seller_name,
             COALESCE(SUM(o.total),0)::numeric AS sales,
             COUNT(*)::int AS orders
      FROM orders o
      JOIN clients c ON c.id = o.client_id
      LEFT JOIN zones z ON z.id = c.zone_id
      JOIN users u ON u.id = o.seller_id
      ${where}
      GROUP BY u.id, u.full_name
      ORDER BY sales DESC
    `, values);

    return {
      totals: {
        sales: toNum(totals.rows[0].total_sales),
        orders: Number(totals.rows[0].orders_count ?? 0),
        avgTicket: toNum(totals.rows[0].avg_ticket),
      },
      byDay: series.rows.map((r) => ({ day: r.day, sales: toNum(r.total), orders: Number(r.orders ?? 0) })),
      byZone: byZone.rows.map((r) => ({ zone: r.zone, sales: toNum(r.sales), orders: Number(r.orders ?? 0) })),
      bySeller: bySeller.rows.map((r) => ({ sellerId: r.seller_id, sellerName: r.seller_name, sales: toNum(r.sales), orders: Number(r.orders ?? 0) })),
    };
  }

  async getProfit(query, user) {
    this.ensureAccess(user);
    const { where, values } = buildOrderFilters(query, user);
    const itemFilters = buildItemExtraFilters(query, values);
    const itemWhere = itemFilters.length ? ` AND ${itemFilters.join(' AND ')}` : '';

    const base = await pool.query(`
      SELECT
        COALESCE(SUM(oi.quantity * COALESCE(oi.cost, 0)),0)::numeric AS cost_total,
        COALESCE(SUM(oi.subtotal),0)::numeric AS sales_total,
        COALESCE(SUM(oi.subtotal - (oi.quantity * COALESCE(oi.cost, 0))),0)::numeric AS gross_profit
      FROM orders o
      JOIN clients c ON c.id = o.client_id
      LEFT JOIN zones z ON z.id = c.zone_id
      JOIN order_items oi ON oi.order_id = o.id
      JOIN products p ON p.id = oi.product_id
      LEFT JOIN product_categories pc ON pc.id = p.category_id
      ${where}
      ${itemWhere}
    `, values);

    const byProduct = await pool.query(`
      SELECT oi.product_id,
             COALESCE(oi.variant_name_snapshot, oi.product_name, p.name) AS product_name,
             COALESCE(SUM(oi.subtotal - (oi.quantity * COALESCE(oi.cost,0))),0)::numeric AS profit
      FROM orders o
      JOIN clients c ON c.id = o.client_id
      LEFT JOIN zones z ON z.id = c.zone_id
      JOIN order_items oi ON oi.order_id = o.id
      JOIN products p ON p.id = oi.product_id
      LEFT JOIN product_categories pc ON pc.id = p.category_id
      ${where}
      ${itemWhere}
      GROUP BY oi.product_id, COALESCE(oi.variant_name_snapshot, oi.product_name, p.name)
      ORDER BY profit DESC
      LIMIT 20
    `, values);

    const byClient = await pool.query(`
      SELECT c.id AS client_id, c.business_name,
             COALESCE(SUM(oi.subtotal - (oi.quantity * COALESCE(oi.cost,0))),0)::numeric AS profit
      FROM orders o
      JOIN clients c ON c.id = o.client_id
      LEFT JOIN zones z ON z.id = c.zone_id
      JOIN order_items oi ON oi.order_id = o.id
      JOIN products p ON p.id = oi.product_id
      LEFT JOIN product_categories pc ON pc.id = p.category_id
      ${where}
      ${itemWhere}
      GROUP BY c.id, c.business_name
      ORDER BY profit DESC
      LIMIT 20
    `, values);

    const bySeller = await pool.query(`
      SELECT u.id AS seller_id, u.full_name,
             COALESCE(SUM(oi.subtotal - (oi.quantity * COALESCE(oi.cost,0))),0)::numeric AS profit
      FROM orders o
      JOIN clients c ON c.id = o.client_id
      LEFT JOIN zones z ON z.id = c.zone_id
      JOIN users u ON u.id = o.seller_id
      JOIN order_items oi ON oi.order_id = o.id
      JOIN products p ON p.id = oi.product_id
      LEFT JOIN product_categories pc ON pc.id = p.category_id
      ${where}
      ${itemWhere}
      GROUP BY u.id, u.full_name
      ORDER BY profit DESC
      LIMIT 20
    `, values);

    const byCategory = await pool.query(`
      SELECT COALESCE(pc.name, p.category, 'Sin categoría') AS category,
             COALESCE(SUM(oi.subtotal - (oi.quantity * COALESCE(oi.cost,0))),0)::numeric AS profit
      FROM orders o
      JOIN clients c ON c.id = o.client_id
      LEFT JOIN zones z ON z.id = c.zone_id
      JOIN order_items oi ON oi.order_id = o.id
      JOIN products p ON p.id = oi.product_id
      LEFT JOIN product_categories pc ON pc.id = p.category_id
      ${where}
      ${itemWhere}
      GROUP BY COALESCE(pc.name, p.category, 'Sin categoría')
      ORDER BY profit DESC
      LIMIT 20
    `, values);

    const byZone = await pool.query(`
      SELECT COALESCE(z.name, c.route_zone, 'Sin zona') AS zone,
             COALESCE(SUM(oi.subtotal - (oi.quantity * COALESCE(oi.cost,0))),0)::numeric AS profit
      FROM orders o
      JOIN clients c ON c.id = o.client_id
      LEFT JOIN zones z ON z.id = c.zone_id
      JOIN order_items oi ON oi.order_id = o.id
      JOIN products p ON p.id = oi.product_id
      LEFT JOIN product_categories pc ON pc.id = p.category_id
      ${where}
      ${itemWhere}
      GROUP BY COALESCE(z.name, c.route_zone, 'Sin zona')
      ORDER BY profit DESC
      LIMIT 20
    `, values);

    const costTotal = toNum(base.rows[0].cost_total);
    const salesTotal = toNum(base.rows[0].sales_total);
    const grossProfit = toNum(base.rows[0].gross_profit);

    return {
      totals: {
        costTotal,
        salesTotal,
        grossProfit,
        avgMargin: salesTotal > 0 ? Number(((grossProfit / salesTotal) * 100).toFixed(2)) : 0,
      },
      byProduct: byProduct.rows.map((r) => ({ productId: r.product_id, productName: r.product_name, profit: toNum(r.profit) })),
      byClient: byClient.rows.map((r) => ({ clientId: r.client_id, businessName: r.business_name, profit: toNum(r.profit) })),
      bySeller: bySeller.rows.map((r) => ({ sellerId: r.seller_id, sellerName: r.full_name, profit: toNum(r.profit) })),
      byCategory: byCategory.rows.map((r) => ({ category: r.category, profit: toNum(r.profit) })),
      byZone: byZone.rows.map((r) => ({ zone: r.zone, profit: toNum(r.profit) })),
    };
  }

  async getTopClients(query, user) {
    this.ensureAccess(user);
    const { where, values } = buildOrderFilters(query, user);
    const limit = query.limit ?? 20;

    values.push(limit);
    const topBuyers = await pool.query(`
      SELECT c.id AS client_id, c.business_name,
             COALESCE(z.name, c.route_zone) AS zone,
             COALESCE(SUM(o.total),0)::numeric AS total_bought,
             COUNT(DISTINCT o.id)::int AS orders_count,
             MAX(o.order_date) AS last_purchase,
             COALESCE(MAX(c.current_balance),0)::numeric AS current_balance
      FROM orders o
      JOIN clients c ON c.id = o.client_id
      LEFT JOIN zones z ON z.id = c.zone_id
      ${where}
      GROUP BY c.id, c.business_name, COALESCE(z.name, c.route_zone)
      ORDER BY total_bought DESC
      LIMIT $${values.length}
    `, values);

    const debtors = await pool.query(`
      SELECT c.id AS client_id, c.business_name,
             COALESCE(z.name, c.route_zone) AS zone,
             COALESCE(c.current_balance,0)::numeric AS current_balance
      FROM clients c
      LEFT JOIN zones z ON z.id = c.zone_id
      WHERE c.current_balance > 0
      ORDER BY c.current_balance DESC
      LIMIT $1
    `, [limit]);

    const inactive = await pool.query(`
      SELECT c.id AS client_id, c.business_name,
             COALESCE(z.name, c.route_zone) AS zone,
             MAX(o.order_date) AS last_purchase,
             COALESCE(c.current_balance,0)::numeric AS current_balance
      FROM clients c
      LEFT JOIN zones z ON z.id = c.zone_id
      LEFT JOIN orders o ON o.client_id = c.id AND o.status <> 'cancelado'
      GROUP BY c.id, c.business_name, COALESCE(z.name, c.route_zone), c.current_balance
      HAVING MAX(o.order_date) IS NULL OR MAX(o.order_date) < NOW() - INTERVAL '45 days'
      ORDER BY MAX(o.order_date) NULLS FIRST
      LIMIT $1
    `, [limit]);

    return {
      topBuyers: topBuyers.rows.map((r) => ({
        clientId: r.client_id,
        businessName: r.business_name,
        zone: r.zone,
        totalBought: toNum(r.total_bought),
        ordersCount: Number(r.orders_count ?? 0),
        lastPurchase: r.last_purchase,
        currentBalance: toNum(r.current_balance),
      })),
      topDebtors: debtors.rows.map((r) => ({ clientId: r.client_id, businessName: r.business_name, zone: r.zone, currentBalance: toNum(r.current_balance) })),
      inactive: inactive.rows.map((r) => ({ clientId: r.client_id, businessName: r.business_name, zone: r.zone, lastPurchase: r.last_purchase, currentBalance: toNum(r.current_balance) })),
    };
  }

  async getTopProducts(query, user) {
    this.ensureAccess(user);
    const { where, values } = buildOrderFilters(query, user);
    const itemFilters = buildItemExtraFilters(query, values);
    const itemWhere = itemFilters.length ? ` AND ${itemFilters.join(' AND ')}` : '';
    const limit = query.limit ?? 20;

    values.push(limit);
    const topByQuantity = await pool.query(`
      SELECT oi.product_id,
             oi.product_variant_id,
             COALESCE(oi.variant_name_snapshot, oi.product_name, p.name) AS product_name,
             COALESCE(SUM(oi.quantity),0)::numeric AS quantity,
             COALESCE(SUM(oi.subtotal),0)::numeric AS revenue,
             COALESCE(SUM(oi.subtotal - (oi.quantity * COALESCE(oi.cost,0))),0)::numeric AS profit
      FROM orders o
      JOIN clients c ON c.id = o.client_id
      LEFT JOIN zones z ON z.id = c.zone_id
      JOIN order_items oi ON oi.order_id = o.id
      JOIN products p ON p.id = oi.product_id
      LEFT JOIN product_categories pc ON pc.id = p.category_id
      ${where}
      ${itemWhere}
      GROUP BY oi.product_id, oi.product_variant_id, COALESCE(oi.variant_name_snapshot, oi.product_name, p.name)
      ORDER BY quantity DESC
      LIMIT $${values.length}
    `, values);

    const lowRotation = await pool.query(`
      SELECT p.id AS product_id,
             p.name AS product_name,
             COALESCE(SUM(oi.quantity),0)::numeric AS quantity,
             MAX(o.order_date) AS last_sale
      FROM products p
      LEFT JOIN order_items oi ON oi.product_id = p.id
      LEFT JOIN orders o ON o.id = oi.order_id AND o.status <> 'cancelado'
      GROUP BY p.id, p.name
      HAVING COALESCE(SUM(oi.quantity),0) < 5
      ORDER BY quantity ASC
      LIMIT $1
    `, [limit]);

    const noRecentSales = await pool.query(`
      SELECT p.id AS product_id,
             p.name AS product_name,
             MAX(o.order_date) AS last_sale
      FROM products p
      LEFT JOIN order_items oi ON oi.product_id = p.id
      LEFT JOIN orders o ON o.id = oi.order_id AND o.status <> 'cancelado'
      GROUP BY p.id, p.name
      HAVING MAX(o.order_date) IS NULL OR MAX(o.order_date) < NOW() - INTERVAL '45 days'
      ORDER BY MAX(o.order_date) NULLS FIRST
      LIMIT $1
    `, [limit]);

    return {
      topByQuantity: topByQuantity.rows.map((r) => ({
        productId: r.product_id,
        variantId: r.product_variant_id,
        productName: r.product_name,
        quantity: toNum(r.quantity),
        revenue: toNum(r.revenue),
        profit: toNum(r.profit),
      })),
      topByRevenue: [...topByQuantity.rows]
        .sort((a, b) => toNum(b.revenue) - toNum(a.revenue))
        .map((r) => ({ productId: r.product_id, variantId: r.product_variant_id, productName: r.product_name, revenue: toNum(r.revenue) })),
      topByProfit: [...topByQuantity.rows]
        .sort((a, b) => toNum(b.profit) - toNum(a.profit))
        .map((r) => ({ productId: r.product_id, variantId: r.product_variant_id, productName: r.product_name, profit: toNum(r.profit) })),
      lowRotation: lowRotation.rows.map((r) => ({ productId: r.product_id, productName: r.product_name, quantity: toNum(r.quantity), lastSale: r.last_sale })),
      noRecentSales: noRecentSales.rows.map((r) => ({ productId: r.product_id, productName: r.product_name, lastSale: r.last_sale })),
    };
  }

  async getDebt(query, user) {
    this.ensureAccess(user);
    const limit = query.limit ?? 20;
    const totals = await pool.query(`
      SELECT COALESCE(SUM(current_balance),0)::numeric AS total_debt,
             COUNT(*)::int AS clients_with_debt
      FROM clients
      WHERE current_balance > 0
    `);

    const topDebtors = await pool.query(`
      SELECT c.id AS client_id, c.business_name, COALESCE(z.name, c.route_zone) AS zone,
             c.current_balance::numeric AS balance, c.credit_limit::numeric AS credit_limit
      FROM clients c
      LEFT JOIN zones z ON z.id = c.zone_id
      WHERE c.current_balance > 0
      ORDER BY c.current_balance DESC
      LIMIT $1
    `, [limit]);

    const debtByZone = await pool.query(`
      SELECT COALESCE(z.name, c.route_zone, 'Sin zona') AS zone,
             COALESCE(SUM(c.current_balance),0)::numeric AS debt,
             COUNT(*) FILTER (WHERE c.current_balance > 0)::int AS clients_with_debt
      FROM clients c
      LEFT JOIN zones z ON z.id = c.zone_id
      GROUP BY COALESCE(z.name, c.route_zone, 'Sin zona')
      ORDER BY debt DESC
    `);

    const recentMovements = await pool.query(`
      SELECT am.id, am.client_id, c.business_name, am.movement_type, am.amount, am.new_balance, am.reference_type, am.reference_id, am.created_at
      FROM account_movements am
      JOIN clients c ON c.id = am.client_id
      ORDER BY am.created_at DESC
      LIMIT 20
    `);

    return {
      totalDebt: toNum(totals.rows[0].total_debt),
      clientsWithDebt: Number(totals.rows[0].clients_with_debt ?? 0),
      topDebtors: topDebtors.rows.map((r) => ({
        clientId: r.client_id,
        businessName: r.business_name,
        zone: r.zone,
        balance: toNum(r.balance),
        creditLimit: toNum(r.credit_limit),
      })),
      debtByZone: debtByZone.rows.map((r) => ({
        zone: r.zone,
        debt: toNum(r.debt),
        clientsWithDebt: Number(r.clients_with_debt ?? 0),
      })),
      recentMovements: recentMovements.rows.map((r) => ({
        id: r.id,
        clientId: r.client_id,
        businessName: r.business_name,
        movementType: r.movement_type,
        amount: toNum(r.amount),
        newBalance: toNum(r.new_balance),
        referenceType: r.reference_type,
        referenceId: r.reference_id,
        createdAt: r.created_at,
      })),
    };
  }

  async getStockReport(query, user) {
    this.ensureAccess(user);
    const rows = await pool.query(`
      SELECT p.id, p.name, p.stock_current::numeric, p.stock_minimum::numeric,
             (p.stock_minimum - p.stock_current)::numeric AS shortage
      FROM products p
      WHERE p.is_active = TRUE AND p.stock_current <= p.stock_minimum
      ORDER BY shortage DESC
      LIMIT $1
    `, [query.limit ?? 50]);

    return rows.rows.map((r) => ({
      productId: r.id,
      productName: r.name,
      stockCurrent: toNum(r.stock_current),
      stockMinimum: toNum(r.stock_minimum),
      shortage: toNum(r.shortage),
    }));
  }

  async getPayments(query, user) {
    this.ensureAccess(user);
    const filters = ['cp.is_annulled = FALSE'];
    const values = [];
    addDateFilters(filters, values, query, 'cp.created_at');

    const where = filters.length ? `WHERE ${filters.join(' AND ')}` : '';

    const total = await pool.query(`
      SELECT COALESCE(SUM(cp.amount),0)::numeric AS total, COUNT(*)::int AS count
      FROM client_payments cp
      ${where}
    `, values);

    const byMethod = await pool.query(`
      SELECT cp.payment_method, COALESCE(SUM(cp.amount),0)::numeric AS total, COUNT(*)::int AS count
      FROM client_payments cp
      ${where}
      GROUP BY cp.payment_method
      ORDER BY total DESC
    `, values);

    const byDay = await pool.query(`
      SELECT cp.created_at::date AS day, COALESCE(SUM(cp.amount),0)::numeric AS total
      FROM client_payments cp
      ${where}
      GROUP BY cp.created_at::date
      ORDER BY cp.created_at::date ASC
    `, values);

    const byUser = await pool.query(`
      SELECT cp.user_id, COALESCE(u.full_name, 'Usuario') AS user_name,
             COALESCE(SUM(cp.amount),0)::numeric AS total, COUNT(*)::int AS count
      FROM client_payments cp
      LEFT JOIN users u ON u.id = cp.user_id
      ${where}
      GROUP BY cp.user_id, COALESCE(u.full_name, 'Usuario')
      ORDER BY total DESC
    `, values);

    const recent = await pool.query(`
      SELECT cp.id, cp.client_id, c.business_name, cp.payment_method, cp.amount::numeric, cp.user_id,
             COALESCE(u.full_name, 'Usuario') AS user_name, cp.created_at
      FROM client_payments cp
      JOIN clients c ON c.id = cp.client_id
      LEFT JOIN users u ON u.id = cp.user_id
      ${where}
      ORDER BY cp.created_at DESC
      LIMIT 20
    `, values);

    const today = await pool.query(`
      SELECT COALESCE(SUM(amount),0)::numeric AS total, COUNT(*)::int AS count
      FROM client_payments
      WHERE is_annulled = FALSE
        AND created_at::date = CURRENT_DATE
    `);
    const month = await pool.query(`
      SELECT COALESCE(SUM(amount),0)::numeric AS total, COUNT(*)::int AS count
      FROM client_payments
      WHERE is_annulled = FALSE
        AND created_at::date >= date_trunc('month', CURRENT_DATE)::date
    `);

    return {
      totals: { amount: toNum(total.rows[0].total), count: Number(total.rows[0].count ?? 0) },
      today: { amount: toNum(today.rows[0].total), count: Number(today.rows[0].count ?? 0) },
      month: { amount: toNum(month.rows[0].total), count: Number(month.rows[0].count ?? 0) },
      byMethod: byMethod.rows.map((r) => ({ method: r.payment_method, total: toNum(r.total), count: Number(r.count ?? 0) })),
      byDay: byDay.rows.map((r) => ({ day: r.day, total: toNum(r.total) })),
      byUser: byUser.rows.map((r) => ({ userId: r.user_id, userName: r.user_name, total: toNum(r.total), count: Number(r.count ?? 0) })),
      recent: recent.rows.map((r) => ({
        id: r.id,
        clientId: r.client_id,
        businessName: r.business_name,
        method: r.payment_method,
        amount: toNum(r.amount),
        userId: r.user_id,
        userName: r.user_name,
        createdAt: r.created_at,
      })),
    };
  }

  async getZones(query, user) {
    this.ensureAccess(user);
    const { where, values } = buildOrderFilters(query, user);

    const rows = await pool.query(`
      SELECT
        COALESCE(z.id::text, c.zone_id::text, '') AS zone_id,
        COALESCE(z.name, c.route_zone, 'Sin zona') AS zone,
        COALESCE(SUM(o.total),0)::numeric AS sales,
        COUNT(o.id)::int AS orders,
        COALESCE(SUM(c.current_balance) FILTER (WHERE c.current_balance > 0),0)::numeric AS debt,
        COUNT(DISTINCT c.id)::int AS clients,
        COALESCE(SUM(oi.quantity),0)::numeric AS sold_units
      FROM orders o
      JOIN clients c ON c.id = o.client_id
      LEFT JOIN zones z ON z.id = c.zone_id
      LEFT JOIN order_items oi ON oi.order_id = o.id
      ${where}
      GROUP BY COALESCE(z.id::text, c.zone_id::text, ''), COALESCE(z.name, c.route_zone, 'Sin zona')
      ORDER BY sales DESC
    `, values);

    return rows.rows.map((r) => ({
      zoneId: r.zone_id,
      zone: r.zone,
      sales: toNum(r.sales),
      orders: Number(r.orders ?? 0),
      debt: toNum(r.debt),
      clients: Number(r.clients ?? 0),
      soldUnits: toNum(r.sold_units),
    }));
  }
}

export const reportService = new ReportService();
