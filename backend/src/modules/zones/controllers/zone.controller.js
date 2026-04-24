import { created, ok } from '../../../utils/api-response.js';
import { zoneService } from '../services/zone.service.js';

export const listZonesController = async (req, res) => {
  const data = await zoneService.list(req.query.includeInactive === 'true');
  return ok(res, data, 'Zonas obtenidas correctamente.');
};

export const createZoneController = async (req, res) => {
  const data = await zoneService.create(req.body);
  return created(res, data, 'Zona creada correctamente.');
};

export const updateZoneController = async (req, res) => {
  const data = await zoneService.update(req.params.id, req.body);
  return ok(res, data, 'Zona actualizada correctamente.');
};

export const deactivateZoneController = async (req, res) => {
  const data = await zoneService.deactivate(req.params.id);
  return ok(res, data, 'Zona desactivada correctamente.');
};

export const moveZoneClientsController = async (req, res) => {
  const data = await zoneService.moveClients(req.params.id, req.body.zoneId);
  return ok(res, data, 'Clientes movidos de zona correctamente.');
};

export const deleteZoneController = async (req, res) => {
  const data = await zoneService.remove(req.params.id);
  return ok(res, data, 'Zona eliminada correctamente.');
};
