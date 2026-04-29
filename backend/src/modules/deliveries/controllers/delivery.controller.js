import { deliveryService } from '../services/delivery.service.js';
import { runIdempotent } from '../../../utils/idempotency.js';

export const listDeliveriesController = async (req, res) => {
  const result = await deliveryService.list(req.query, req.user);
  res.json({
    message: 'Repartos obtenidos.',
    data: {
      items: result.rows,
      total: result.total,
      page: Number(req.query.page ?? 1),
      limit: Number(req.query.limit ?? 20),
    },
  });
};

export const listDeliveryZonesController = async (_req, res) => {
  const rows = await deliveryService.listZones();
  res.json({ message: 'Zonas para reparto obtenidas.', data: { items: rows, total: rows.length } });
};

export const createDeliveryController = async (req, res) => {
  const row = await deliveryService.create(req.body, req.user);
  res.status(201).json({ message: 'Reparto creado.', data: row });
};

export const getDeliveryByIdController = async (req, res) => {
  const row = await deliveryService.getById(req.params.id, req.user);
  res.json({ message: 'Reparto obtenido.', data: row });
};

export const changeDeliveryStatusController = async (req, res) => {
  const row = await deliveryService.updateStatus(req.params.id, req.body.status);
  res.json({ message: 'Estado de reparto actualizado.', data: row });
};

export const assignDeliveryDriverController = async (req, res) => {
  const row = await deliveryService.assignDriver(req.params.id, req.body.driverId);
  res.json({ message: 'Repartidor asignado.', data: row });
};

export const addOrdersToDeliveryController = async (req, res) => {
  const row = await deliveryService.addOrders(req.params.id, req.body.orderIds);
  res.status(201).json({ message: 'Pedidos asignados al reparto.', data: row });
};

export const listPendingDeliveryOrdersController = async (req, res) => {
  const rows = await deliveryService.listPendingOrders(req.query.zoneId ?? req.query.zone_id);
  res.json({ message: 'Pedidos pendientes para reparto.', data: { items: rows, total: rows.length } });
};

export const todayRoutesController = async (req, res) => {
  const rows = await deliveryService.todayRoutes(req.user);
  res.json({ message: 'Rutas del día obtenidas.', data: { items: rows, total: rows.length } });
};

export const updateDeliveryOrderStatusController = async (req, res) => {
  const row = await deliveryService.updateDeliveryOrderStatus(req.params.deliveryOrderId, req.body, req.user);
  res.json({ message: 'Estado de entrega actualizado.', data: row });
};

export const optimizeDeliveryRouteController = async (req, res) => {
  const data = await deliveryService.optimizeRoute(
    req.params.id,
    req.body.currentLatitude,
    req.body.currentLongitude,
    req.user,
  );
  res.json({ message: 'Recorrido optimizado.', data });
};

export const markDeliveryOrderDeliveredController = async (req, res) => {
  const result = await runIdempotent({
    userId: req.user.sub,
    action: 'mark_delivery_status',
    clientRequestId: req.body.clientRequestId,
    execute: async () => ({
      statusCode: 200,
      body: { message: 'Pedido marcado como entregado.', data: await deliveryService.markDelivered(req.params.id, req.body, req.user) },
    }),
  });
  res.status(result.statusCode).json(result.body);
};

export const markDeliveryOrderNotDeliveredController = async (req, res) => {
  const result = await runIdempotent({
    userId: req.user.sub,
    action: 'mark_delivery_status',
    clientRequestId: req.body.clientRequestId,
    execute: async () => ({
      statusCode: 200,
      body: { message: 'Pedido marcado como no entregado.', data: await deliveryService.markNotDelivered(req.params.id, req.body, req.user) },
    }),
  });
  res.status(result.statusCode).json(result.body);
};

export const markDeliveryOrderRescheduleController = async (req, res) => {
  const result = await runIdempotent({
    userId: req.user.sub,
    action: 'mark_delivery_status',
    clientRequestId: req.body.clientRequestId,
    execute: async () => ({
      statusCode: 200,
      body: { message: 'Pedido reprogramado.', data: await deliveryService.markRescheduled(req.params.id, req.body, req.user) },
    }),
  });
  res.status(result.statusCode).json(result.body);
};

export const archiveDeliveryController = async (req, res) => {
  const data = await deliveryService.archive(req.params.id, req.user, req.body?.reason);
  res.json({ message: 'Reparto archivado.', data });
};
