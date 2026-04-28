import { pool } from '../../../database/pool.js';

const relationExists = async (relationName) => {
  const result = await pool.query('SELECT to_regclass($1) IS NOT NULL AS exists', [relationName]);
  return result.rows[0]?.exists === true;
};

export class DashboardService {
  async getStats() {
    const [clientsTableExists, productsTableExists, ordersTableExists, orderItemsTableExists, paymentsTableExists] = await Promise.all([
      relationExists('public.clients'),
      relationExists('public.products'),
      relationExists('public.orders'),
      relationExists('public.order_items'),
      relationExists('public.client_payments'),
    ]);

    const businessMetrics = ordersTableExists
      ? pool.query(`
          SELECT
            COALESCE(SUM(total) FILTER (WHERE status <> 'cancelado' AND order_date::date = CURRENT_DATE), 0)::numeric AS sales_today,
            COALESCE(SUM(total) FILTER (WHERE status <> 'cancelado' AND order_date::date >= date_trunc('month', CURRENT_DATE)::date), 0)::numeric AS sales_month,
            COUNT(*) FILTER (WHERE status = 'pendiente')::int AS pending_orders,
            COUNT(*) FILTER (WHERE status = 'preparado')::int AS prepared_orders,
            COUNT(*) FILTER (WHERE status = 'en_reparto')::int AS delivery_orders,
            COUNT(*) FILTER (WHERE status = 'entregado' AND updated_at::date = CURRENT_DATE)::int AS delivered_today
          FROM orders
        `)
      : Promise.resolve({ rows: [{ sales_today: 0, sales_month: 0, pending_orders: 0, prepared_orders: 0, delivery_orders: 0, delivered_today: 0 }] });

    const debtMetrics = clientsTableExists
      ? pool.query(`
          SELECT
            COALESCE(SUM(current_balance) FILTER (WHERE current_balance > 0), 0)::numeric AS total_debt,
            COUNT(*) FILTER (WHERE current_balance > 0)::int AS clients_with_debt
          FROM clients
          WHERE COALESCE(is_active, TRUE) = TRUE
        `)
      : Promise.resolve({ rows: [{ total_debt: 0, clients_with_debt: 0 }] });

    const paymentsToday = paymentsTableExists
      ? pool.query(`
          SELECT
            COUNT(*)::int AS payments_today,
            COALESCE(SUM(amount), 0)::numeric AS collected_today
          FROM client_payments
          WHERE created_at::date = CURRENT_DATE
            AND is_annulled = FALSE
        `)
      : Promise.resolve({ rows: [{ payments_today: 0, collected_today: 0 }] });

    const stockMetrics = productsTableExists
      ? pool.query(`
          SELECT
            COUNT(*) FILTER (WHERE COALESCE(is_active, TRUE) = TRUE AND stock_current <= 0)::int AS out_of_stock_products,
            COUNT(*) FILTER (WHERE COALESCE(is_active, TRUE) = TRUE AND stock_current > 0 AND stock_current <= stock_minimum)::int AS low_stock_products
          FROM products
        `)
      : Promise.resolve({ rows: [{ out_of_stock_products: 0, low_stock_products: 0 }] });

    const topProducts = (ordersTableExists && orderItemsTableExists)
      ? pool.query(`
          SELECT
            oi.product_id,
            COALESCE(oi.variant_name_snapshot, oi.product_name_snapshot, oi.product_name, 'Producto') AS product_name,
            COALESCE(SUM(oi.quantity), 0)::numeric AS units
          FROM order_items oi
          JOIN orders o ON o.id = oi.order_id
          WHERE o.status <> 'cancelado'
            AND o.order_date::date >= date_trunc('month', CURRENT_DATE)::date
          GROUP BY oi.product_id, COALESCE(oi.variant_name_snapshot, oi.product_name_snapshot, oi.product_name, 'Producto')
          ORDER BY units DESC
          LIMIT 3
        `)
      : Promise.resolve({ rows: [] });

    const profitEstimate = (ordersTableExists && orderItemsTableExists)
      ? pool.query(`
          SELECT COALESCE(SUM(oi.subtotal - (oi.quantity * COALESCE(oi.cost, 0))), 0)::numeric AS profit_estimate
          FROM order_items oi
          JOIN orders o ON o.id = oi.order_id
          WHERE o.status <> 'cancelado'
            AND o.order_date::date >= date_trunc('month', CURRENT_DATE)::date
        `)
      : Promise.resolve({ rows: [{ profit_estimate: 0 }] });

    const zonesMetrics = clientsTableExists
      ? pool.query(`
          SELECT
            z.id AS zone_id,
            z.name AS zone_name,
            COALESCE(SUM(o.total) FILTER (
              WHERE o.status <> 'cancelado'
                AND o.order_date::date >= date_trunc('month', CURRENT_DATE)::date
            ), 0)::numeric AS sales,
            COALESCE(COUNT(o.id) FILTER (
              WHERE o.status <> 'cancelado'
                AND o.order_date::date >= date_trunc('month', CURRENT_DATE)::date
            ), 0)::int AS orders,
            COALESCE(SUM(c.current_balance) FILTER (WHERE c.current_balance > 0), 0)::numeric AS debt,
            COUNT(DISTINCT c.id)::int AS clients
          FROM zones z
          LEFT JOIN clients c ON c.zone_id = z.id
          LEFT JOIN orders o ON o.client_id = c.id
          GROUP BY z.id, z.name
          ORDER BY z.name ASC
        `)
      : Promise.resolve({ rows: [] });

    const [businessResult, debtResult, paymentsTodayResult, stockResult, topProductsResult, profitResult, zonesResult] = await Promise.all([
      businessMetrics,
      debtMetrics,
      paymentsToday,
      stockMetrics,
      topProducts,
      profitEstimate,
      zonesMetrics,
    ]);

    const business = businessResult.rows[0];
    const debt = debtResult.rows[0];
    const payments = paymentsTodayResult.rows[0];
    const stock = stockResult.rows[0];

    return {
      salesToday: Number(business.sales_today ?? 0),
      salesMonth: Number(business.sales_month ?? 0),
      pendingOrders: Number(business.pending_orders ?? 0),
      preparedOrders: Number(business.prepared_orders ?? 0),
      deliveryOrders: Number(business.delivery_orders ?? 0),
      deliveredToday: Number(business.delivered_today ?? 0),
      totalDebt: Number(debt.total_debt ?? 0),
      clientsWithDebt: Number(debt.clients_with_debt ?? 0),
      paymentsToday: Number(payments.payments_today ?? 0),
      collectedToday: Number(payments.collected_today ?? 0),
      outOfStockProducts: Number(stock.out_of_stock_products ?? 0),
      lowStockProducts: Number(stock.low_stock_products ?? 0),
      topProducts: topProductsResult.rows.map((row) => ({
        productId: row.product_id,
        productName: row.product_name,
        units: Number(row.units ?? 0),
      })),
      profitEstimate: Number(profitResult.rows[0]?.profit_estimate ?? 0),
      zones: zonesResult.rows.map((row) => ({
        zoneId: row.zone_id,
        zoneName: row.zone_name,
        sales: Number(row.sales ?? 0),
        orders: Number(row.orders ?? 0),
        debt: Number(row.debt ?? 0),
        clients: Number(row.clients ?? 0),
      })),
    };
  }
}

export const dashboardService = new DashboardService();
