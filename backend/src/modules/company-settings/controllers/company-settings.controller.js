import { ok } from '../../../utils/api-response.js';
import { companySettingsService } from '../services/company-settings.service.js';

export const getCompanySettingsController = async (_req, res) => {
  const data = await companySettingsService.get();
  return ok(res, data, 'Configuración de empresa obtenida correctamente.');
};

export const upsertCompanySettingsController = async (req, res) => {
  const data = await companySettingsService.upsert(req.body);
  return ok(res, data, 'Configuración de empresa guardada correctamente.');
};

export const resetCompanySettingsController = async (_req, res) => {
  const data = await companySettingsService.resetDefaults();
  return ok(res, data, 'Configuración de empresa restablecida a valores por defecto.');
};
