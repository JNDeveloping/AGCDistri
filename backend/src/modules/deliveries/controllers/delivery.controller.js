import { deliveryService } from '../services/delivery.service.js';

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
  const rows = await deliveryService.listPendingOrders(req.query.zone);
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
