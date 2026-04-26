import { AppError } from '../../../errors/app-error.js';
import { AccountService } from '../../accounts/services/account.service.js';
import { DeliveryRepository } from '../repositories/delivery.repository.js';

const FINAL_STATUSES = new Set(['finalizado', 'cancelado']);

export class DeliveryService {
  constructor() {
    this.repository = new DeliveryRepository();
    this.accountService = new AccountService();
  }

  async list(input, authUser) {
    return this.repository.list({
      ...input,
      role: authUser.role,
      userId: authUser.sub,
    });
  }

  async create(payload, authUser) {
    return this.repository.create({ ...payload, createdBy: authUser.id });
  }

  async getById(id, authUser) {
    const delivery = await this.repository.findById(id);
    if (!delivery) throw new AppError('Reparto no encontrado.', 404);

    if (authUser.role === 'repartidor' && delivery.driver_id !== authUser.sub) {
      throw new AppError('No autorizado para ver este reparto.', 403);
    }

    const orders = await this.repository.listOrders(id);
    return { ...delivery, orders };
  }

  async updateStatus(id, status) {
    const delivery = await this.repository.findById(id);
    if (!delivery) throw new AppError('Reparto no encontrado.', 404);
    if (FINAL_STATUSES.has(delivery.status)) throw new AppError('El reparto finalizado/cancelado no se puede modificar.', 409);

    const updated = await this.repository.updateStatus(id, status);
    return updated;
  }

  async assignDriver(id, driverId) {
    const delivery = await this.repository.findById(id);
    if (!delivery) throw new AppError('Reparto no encontrado.', 404);
    if (FINAL_STATUSES.has(delivery.status)) throw new AppError('No se puede asignar repartidor en un reparto cerrado.', 409);

    return this.repository.assignDriver(id, driverId);
  }

  async addOrders(id, orderIds) {
    const delivery = await this.repository.findById(id);
    if (!delivery) throw new AppError('Reparto no encontrado.', 404);
    if (FINAL_STATUSES.has(delivery.status)) throw new AppError('No se pueden agregar pedidos a un reparto cerrado.', 409);

    const pending = await this.repository.listPendingDeliveryOrders({ limit: 5000 });
    const pendingSet = new Set(pending.map((item) => item.id));

    for (const orderId of orderIds) {
      if (!pendingSet.has(orderId)) {
        throw new AppError('Solo se pueden asignar pedidos preparados y no asignados a otro reparto activo.', 409, { orderId });
      }

      const inAnotherDelivery = await this.repository.findActiveDeliveryByOrder(orderId, id);
      if (inAnotherDelivery) {
        throw new AppError(`El pedido ya está en un reparto activo #${inAnotherDelivery.number}.`, 409, {
          orderId,
          deliveryId: inAnotherDelivery.id,
        });
      }
    }

    return this.repository.addOrders(id, orderIds);
  }

  async listPendingOrders(zone) {
    return this.repository.listPendingDeliveryOrders({ zone });
  }

  async todayRoutes(authUser) {
    return this.repository.todayRoutes({ role: authUser.role, userId: authUser.sub });
  }

  async optimizeRoute(deliveryId, currentLat, currentLng, authUser) {
    const delivery = await this.repository.findById(deliveryId);
    if (!delivery) throw new AppError('Reparto no encontrado.', 404);
    if (authUser.role === 'repartidor' && delivery.driver_id !== authUser.sub) {
      throw new AppError('No autorizado para optimizar este recorrido.', 403);
    }

    const orders = await this.repository.optimizeRoute(deliveryId, currentLat, currentLng);
    return { deliveryId, orders };
  }

  async updateDeliveryOrderStatus(deliveryOrderId, payload, authUser) {
    const row = await this.repository.findDeliveryOrderById(deliveryOrderId);
    if (!row) throw new AppError('Entrega no encontrada.', 404);
    if (FINAL_STATUSES.has(row.delivery_status)) throw new AppError('El reparto finalizado/cancelado no se puede modificar.', 409);

    const updated = await this.repository.updateDeliveryOrderStatus({
      deliveryOrderId,
      status: payload.status,
      notes: payload.notes,
      reason: payload.reason,
      collectedCash: payload.collectedCash,
      collectedAmount: payload.collectedAmount,
    });

    if (payload.status === 'entregado') {
      await this.repository.updateOrderStatus(row.order_id, 'entregado');
    }

    if (payload.status === 'no_entregado' || payload.status === 'reprogramado') {
      await this.repository.updateOrderStatus(row.order_id, 'preparado');
    }

    if (payload.status === 'entregado' && row.payment_terms === 'contado' && payload.collectedAmount > 0) {
      await this.accountService.registerPayment({
        clientId: row.client_id,
        amount: payload.collectedAmount,
        method: 'efectivo',
        referenceType: 'delivery_order',
        referenceId: row.id,
        notes: 'Cobro registrado desde hoja de ruta',
      }, authUser);
    }

    return updated;
  }
}

export const deliveryService = new DeliveryService();
