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

  async listZones() {
    return this.repository.listZones();
  }

  async create(payload, authUser) {
    const created = await this.repository.create({
      date: payload.date,
      driverId: payload.driverId,
      notes: payload.notes,
      zoneId: payload.zoneId,
      createdBy: authUser.sub,
    });

    if (payload.orderIds?.length) {
      await this.addOrders(created.id, payload.orderIds, payload.zoneId);
    }

    return this.getById(created.id, authUser);
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

  async archive(id, authUser, reason = null) {
    const delivery = await this.repository.findById(id);
    if (!delivery) throw new AppError('Reparto no encontrado.', 404);
    if (delivery.status === 'en_reparto') {
      throw new AppError('No se puede archivar un reparto en curso con pedidos en reparto.', 409);
    }
    await this.repository.archive(id, authUser.sub, reason);
    return { id, archived: true };
  }

  async assignDriver(id, driverId) {
    const delivery = await this.repository.findById(id);
    if (!delivery) throw new AppError('Reparto no encontrado.', 404);
    if (FINAL_STATUSES.has(delivery.status)) throw new AppError('No se puede asignar repartidor en un reparto cerrado.', 409);

    return this.repository.assignDriver(id, driverId);
  }

  async addOrders(id, orderIds, forcedZoneId = null) {
    const delivery = await this.repository.findById(id);
    if (!delivery) throw new AppError('Reparto no encontrado.', 404);
    if (FINAL_STATUSES.has(delivery.status)) throw new AppError('No se pueden agregar pedidos a un reparto cerrado.', 409);

    const zoneId = forcedZoneId ?? delivery.zone_id;
    const pending = await this.repository.listPendingDeliveryOrders({ zoneId, limit: 5000 });
    const pendingSet = new Set(pending.map((item) => item.id));

    for (const orderId of orderIds) {
      if (!pendingSet.has(orderId)) {
        throw new AppError('Solo se pueden asignar pedidos de la zona seleccionada, preparados y no asignados a otro reparto activo.', 409, { orderId });
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

  async listPendingOrders(zoneId) {
    if (!zoneId) throw new AppError('zoneId es requerido.', 400);
    return this.repository.listPendingDeliveryOrders({ zoneId });
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

  async markDelivered(deliveryOrderId, payload, authUser) {
    return this.updateDeliveryOrderStatus(deliveryOrderId, { ...payload, status: 'entregado' }, authUser);
  }

  async markNotDelivered(deliveryOrderId, payload, authUser) {
    return this.updateDeliveryOrderStatus(deliveryOrderId, { ...payload, status: 'no_entregado' }, authUser);
  }

  async markRescheduled(deliveryOrderId, payload, authUser) {
    return this.updateDeliveryOrderStatus(deliveryOrderId, { ...payload, status: 'reprogramado' }, authUser);
  }

  async updateDeliveryOrderStatus(deliveryOrderId, payload, authUser) {
    const row = await this.repository.findDeliveryOrderById(deliveryOrderId);
    if (!row) throw new AppError('Entrega no encontrada.', 404);
    if (FINAL_STATUSES.has(row.delivery_status_parent)) throw new AppError('El reparto finalizado/cancelado no se puede modificar.', 409);
    if (authUser.role === 'repartidor' && row.driver_id !== authUser.sub) {
      throw new AppError('No autorizado para modificar este pedido de reparto.', 403);
    }

    if (payload.status === 'no_entregado' && !payload.reason?.trim()) {
      throw new AppError('El motivo es obligatorio para marcar no entregado.', 400);
    }

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

      if (row.payment_terms === 'cuenta_corriente') {
        await this.accountService.applyOrderDebt({
          orderId: row.order_id,
          clientId: row.client_id,
          total: Number(row.total),
          userId: authUser.sub,
        });
      }

      if (row.payment_terms === 'contado' && Number(payload.collectedAmount ?? 0) > 0) {
        const existingPayment = await this.repository.hasPaymentForDeliveryOrder(deliveryOrderId);
        if (!existingPayment) {
          await this.accountService.registerPayment({
            clientId: row.client_id,
            amount: payload.collectedAmount,
            paymentMethod: 'efectivo',
            referenceType: 'delivery_order',
            referenceId: row.id,
            notes: 'Cobro registrado desde hoja de ruta',
          }, authUser);
        }
      }
    }

    if (payload.status === 'no_entregado' || payload.status === 'reprogramado') {
      await this.repository.updateOrderStatus(row.order_id, 'preparado');
    }

    await this.repository.syncDeliveryStatusFromOrders(row.delivery_id);

    return updated;
  }
}

export const deliveryService = new DeliveryService();
