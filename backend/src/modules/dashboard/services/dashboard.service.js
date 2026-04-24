import { pool } from '../../../database/pool.js';

export class DashboardService {
  async getStats() {
    const [clientsCount, productsCount, lowStockCount, recentClients, recentProducts] = await Promise.all([
      pool.query(`
        SELECT
          COUNT(*)::int AS total,
          COUNT(*) FILTER (WHERE is_active = TRUE)::int AS active
        FROM clients
      `),
      pool.query(`
        SELECT
          COUNT(*)::int AS total,
          COUNT(*) FILTER (WHERE is_active = TRUE)::int AS active
        FROM products
      `),
      pool.query(`SELECT COUNT(*)::int AS low_stock FROM products WHERE stock_current <= stock_minimum AND is_active = TRUE`),
      pool.query(`
        SELECT id, internal_code, business_name, city, province, created_at
        FROM clients
        ORDER BY created_at DESC
        LIMIT 5
      `),
      pool.query(`
        SELECT id, internal_code, name, brand, stock_current, created_at
        FROM products
        ORDER BY created_at DESC
        LIMIT 5
      `),
    ]);

    return {
      clients: clientsCount.rows[0],
      products: productsCount.rows[0],
      lowStockProducts: lowStockCount.rows[0].low_stock,
      recentClients: recentClients.rows.map((row) => ({
        id: row.id,
        internalCode: row.internal_code,
        businessName: row.business_name,
        city: row.city,
        province: row.province,
        createdAt: row.created_at,
      })),
      recentProducts: recentProducts.rows.map((row) => ({
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
