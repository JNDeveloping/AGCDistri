import { ok } from '../../../utils/api-response.js';
import { runIdempotent } from '../../../utils/idempotency.js';
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
      zoneId: req.query.zoneId,
      paymentCondition: req.query.paymentCondition,
      archived: req.query.archived,
      search: req.query.search,
      sortBy: req.query.sortBy,
      sortDirection: req.query.sortDirection,
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

export const listPendingDeliveryOrdersController = async (req, res) => {
  const data = await orderService.listPendingDelivery({
    zoneId: req.query.zoneId,
    role: req.user.role,
    userId: req.user.sub,
  });

  return ok(res, { items: data, total: data.length }, 'Pedidos pendientes para reparto obtenidos correctamente.');
};

export const getOrderController = async (req, res) => {
  const data = await orderService.getById(req.params.id, req.user.role, req.user.sub);
  return ok(res, data, 'Detalle de pedido obtenido correctamente.');
};

export const createOrderController = async (req, res) => {
  const result = await runIdempotent({
    userId: req.user.sub,
    action: 'create_order',
    clientRequestId: req.body.clientRequestId,
    execute: async () => {
      const data = await orderService.create(req.body, req.user);
      return {
        statusCode: 201,
        body: { message: 'Pedido creado correctamente.', data },
      };
    },
  });

  return res.status(result.statusCode).json(result.body);
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

export const validateOrderStockController = async (req, res) => {
  const data = await orderService.validateStockForOrder(req.params.id, req.user.role, req.user.sub);
  return ok(res, data, 'Stock del pedido validado correctamente.');
};

export const deleteOrderController = async (req, res) => {
  const data = await orderService.archive(req.params.id, req.user, req.body?.reason);
  return ok(res, data, 'Pedido archivado correctamente.');
};
