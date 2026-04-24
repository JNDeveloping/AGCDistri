import { pool } from '../../../database/pool.js';

const relationExists = async (relationName) => {
  const result = await pool.query('SELECT to_regclass($1) IS NOT NULL AS exists', [relationName]);
  return result.rows[0]?.exists === true;
};

export class DashboardService {
  async getStats() {
    const clientsTableExists = await relationExists('public.clients');
    const productsTableExists = await relationExists('public.products');

    const clientsCount = clientsTableExists
      ? pool.query(`
          SELECT
            COUNT(*)::int AS total,
            COUNT(*) FILTER (WHERE is_active = TRUE)::int AS active
          FROM clients
        `)
      : Promise.resolve({ rows: [{ total: 0, active: 0 }] });

    const productsCount = productsTableExists
      ? pool.query(`
          SELECT
            COUNT(*)::int AS total,
            COUNT(*) FILTER (WHERE is_active = TRUE)::int AS active
          FROM products
        `)
      : Promise.resolve({ rows: [{ total: 0, active: 0 }] });

    const lowStockCount = productsTableExists
      ? pool.query('SELECT COUNT(*)::int AS low_stock FROM products WHERE stock_current <= stock_minimum AND is_active = TRUE')
      : Promise.resolve({ rows: [{ low_stock: 0 }] });

    const recentClients = clientsTableExists
      ? pool.query(`
          SELECT id, internal_code, business_name, city, province, created_at
          FROM clients
          ORDER BY created_at DESC
          LIMIT 5
        `)
      : Promise.resolve({ rows: [] });

    const recentProducts = productsTableExists
      ? pool.query(`
          SELECT id, internal_code, name, brand, stock_current, created_at
          FROM products
          ORDER BY created_at DESC
          LIMIT 5
        `)
      : Promise.resolve({ rows: [] });

    const stockMovementsExists = await relationExists('public.stock_movements');
    const accountMovementsExists = await relationExists('public.account_movements');
    const paymentsExists = await relationExists('public.client_payments');

    const recentStockMovements = stockMovementsExists
      ? pool.query(`SELECT id, product_id, movement_type, quantity, created_at FROM stock_movements ORDER BY created_at DESC LIMIT 5`)
      : Promise.resolve({ rows: [] });
    const stockMovementsToday = stockMovementsExists
      ? pool.query('SELECT COUNT(*)::int AS total FROM stock_movements WHERE created_at::date = CURRENT_DATE')
      : Promise.resolve({ rows: [{ total: 0 }] });
    const outOfStockCount = productsTableExists
      ? pool.query('SELECT COUNT(*)::int AS total FROM products WHERE stock_current <= 0 AND is_active = TRUE')
      : Promise.resolve({ rows: [{ total: 0 }] });
    const debtSummary = accountMovementsExists
      ? pool.query('SELECT COALESCE(SUM(current_balance),0)::numeric AS total FROM clients WHERE current_balance > 0')
      : Promise.resolve({ rows: [{ total: 0 }] });
    const debtorsCount = accountMovementsExists
      ? pool.query('SELECT COUNT(*)::int AS total FROM clients WHERE current_balance > 0')
      : Promise.resolve({ rows: [{ total: 0 }] });
    const paymentsToday = paymentsExists
      ? pool.query('SELECT COALESCE(SUM(amount),0)::numeric AS total, COUNT(*)::int AS count FROM client_payments WHERE created_at::date = CURRENT_DATE AND is_annulled = FALSE')
      : Promise.resolve({ rows: [{ total: 0, count: 0 }] });

    const [clientsResult, productsResult, lowStockResult, clientsRecentResult, productsRecentResult, stockRecentResult, stockTodayResult, outOfStockResult, debtSummaryResult, debtorsResult, paymentsTodayResult] = await Promise.all([
      clientsCount,
      productsCount,
      lowStockCount,
      recentClients,
      recentProducts,
      recentStockMovements,
      stockMovementsToday,
      outOfStockCount,
      debtSummary,
      debtorsCount,
      paymentsToday,
    ]);

    return {
      clients: clientsResult.rows[0],
      products: productsResult.rows[0],
      lowStockProducts: lowStockResult.rows[0].low_stock,
      recentClients: clientsRecentResult.rows.map((row) => ({
        id: row.id,
        internalCode: row.internal_code,
        businessName: row.business_name,
        city: row.city,
        province: row.province,
        createdAt: row.created_at,
      })),
      recentProducts: productsRecentResult.rows.map((row) => ({
        id: row.id,
        internalCode: row.internal_code,
        name: row.name,
        brand: row.brand,
        stockCurrent: Number(row.stock_current),
        createdAt: row.created_at,
      })),
      stock: {
        lowStockProducts: lowStockResult.rows[0].low_stock,
        outOfStockProducts: outOfStockResult.rows[0].total,
        stockMovementsToday: stockTodayResult.rows[0].total,
        recentMovements: stockRecentResult.rows.map((r) => ({
          id: r.id,
          productId: r.product_id,
          movementType: r.movement_type,
          quantity: Number(r.quantity),
          createdAt: r.created_at,
        })),
      },
      accounts: {
        totalDebt: Number(debtSummaryResult.rows[0].total),
        debtors: debtorsResult.rows[0].total,
        paymentsTodayCount: paymentsTodayResult.rows[0].count,
        paymentsTodayTotal: Number(paymentsTodayResult.rows[0].total),
      },
    };
  }
}

export const dashboardService = new DashboardService();
