import { ok } from '../../../utils/api-response.js';
import { dashboardService } from '../services/dashboard.service.js';

export const getDashboardStatsController = async (_req, res) => {
  const data = await dashboardService.getStats();
  return ok(res, data, 'Métricas de dashboard obtenidas correctamente.');
};
