import { created, ok } from '../../../utils/api-response.js';
import { clientService } from '../services/client.service.js';

export const listClientsController = async (req, res) => {
  const payload = await clientService.list({
    q: req.query.q,
    isActive: req.query.isActive === undefined ? undefined : req.query.isActive === 'true',
    zoneId: req.query.zoneId,
    page: Number(req.query.page ?? 1),
    limit: Number(req.query.limit ?? 20),
    role: req.user.role,
  });

  return ok(res, payload, 'Clientes obtenidos correctamente.');
};

export const getClientController = async (req, res) => {
  const client = await clientService.getById(req.params.id, req.user.role);
  return ok(res, client, 'Detalle de cliente obtenido correctamente.');
};


export const getClientPurchaseHistoryController = async (req, res) => {
  const data = await clientService.getPurchaseHistory(req.params.id);
  return ok(res, { items: data, total: data.length }, 'Historial de compra obtenido correctamente.');
};

export const getClientSuggestedProductsController = async (req, res) => {
  const data = await clientService.getSuggestedProducts(req.params.id);
  return ok(res, { items: data, total: data.length }, 'Productos sugeridos obtenidos correctamente.');
};

export const getClientLastOrderController = async (req, res) => {
  const data = await clientService.getLastOrder(req.params.id);
  return ok(res, data, 'Último pedido obtenido correctamente.');
};

export const createClientController = async (req, res) => {
  const client = await clientService.create(req.body);
  return created(res, client, 'Cliente creado correctamente.');
};

export const updateClientController = async (req, res) => {
  const client = await clientService.update(req.params.id, req.body);
  return ok(res, client, 'Cliente actualizado correctamente.');
};

export const deactivateClientController = async (req, res) => {
  const client = await clientService.deactivate(req.params.id);
  return ok(res, client, 'Cliente desactivado correctamente.');
};

export const activateClientController = async (req, res) => {
  const client = await clientService.activate(req.params.id);
  return ok(res, client, 'Cliente activado correctamente.');
};

export const deleteClientController = async (req, res) => {
  const result = await clientService.remove(req.params.id);
  return ok(res, result, 'Cliente eliminado correctamente.');
};
