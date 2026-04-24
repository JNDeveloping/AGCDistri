import { created, ok } from '../../../utils/api-response.js';
import { orderService } from '../services/order.service.js';

export const listOrdersController = async (req, res) => {
  const data = await orderService.list({
    filters: {
      clientId: req.query.clientId,
      sellerId: req.query.sellerId,
      status: req.query.status,
      dateFrom: req.query.dateFrom,
      dateTo: req.query.dateTo,
      orderNumber: req.query.orderNumber,
    },
    pagination: {
      page: Number(req.query.page ?? 1),
      limit: Number(req.query.limit ?? 20),
    },
    role: req.user.role,
    userId: req.user.sub,
  });

  return ok(res, data, 'Pedidos obtenidos correctamente.');
};

export const getOrderController = async (req, res) => {
  const data = await orderService.getById(req.params.id, req.user.role, req.user.sub);
  return ok(res, data, 'Detalle de pedido obtenido correctamente.');
};

export const createOrderController = async (req, res) => {
  const data = await orderService.create(req.body, req.user);
  return created(res, data, 'Pedido creado correctamente.');
};

export const updateOrderController = async (req, res) => {
  const data = await orderService.update(req.params.id, req.body, req.user);
  return ok(res, data, 'Pedido actualizado correctamente.');
};

export const cancelOrderController = async (req, res) => {
  const data = await orderService.cancel(req.params.id, req.user);
  return ok(res, data, 'Pedido cancelado correctamente.');
};

export const changeOrderStatusController = async (req, res) => {
  const data = await orderService.changeStatus(req.params.id, req.body.status, req.user);
  return ok(res, data, 'Estado de pedido actualizado correctamente.');
};

export const deleteOrderController = async (req, res) => {
  const data = await orderService.remove(req.params.id, req.user);
  return ok(res, data, 'Pedido eliminado correctamente.');
};
