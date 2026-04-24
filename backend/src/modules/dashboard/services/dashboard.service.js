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

    const [clientsResult, productsResult, lowStockResult, clientsRecentResult, productsRecentResult] = await Promise.all([
      clientsCount,
      productsCount,
      lowStockCount,
      recentClients,
      recentProducts,
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
    };
  }
}

export const dashboardService = new DashboardService();
