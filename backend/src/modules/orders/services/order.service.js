import { AppError } from '../../../errors/app-error.js';
import { pool } from '../../../database/pool.js';
import { accountService } from '../../accounts/services/account.service.js';
import { stockService } from '../../stock/services/stock.service.js';
import { promotionService } from '../../promotions/services/promotion.service.js';
import { orderRepository } from '../repositories/order.repository.js';

const editableStatuses = ['pendiente'];
const terminalStatuses = ['entregado', 'cancelado'];
const stockCommitStatuses = ['preparado'];

const mapOrder = (row, items = []) => ({
  id: row.id,
  orderNumber: row.order_number,
  clientId: row.client_id,
  clientName: row.client_name,
  clientPhone: row.client_phone,
  zoneName: row.zone_name,
  zoneId: row.client_zone_id,
  sellerId: row.seller_id,
  sellerName: row.seller_name,
  assignedDeliveryUserId: row.assigned_delivery_user_id,
  assignedDeliveryUserName: row.delivery_user_name,
  orderDate: row.order_date,
  status: row.status,
  notes: row.notes,
  paymentTerms: row.payment_terms,
  subtotal: Number(row.subtotal),
  discountTotal: Number(row.discount_total),
  taxTotal: Number(row.tax_total),
  total: Number(row.total),
  estimatedMargin: Number(row.estimated_margin),
  itemsCount: Number(row.items_count ?? 0),
  totalUnits: Number(row.total_units ?? 0),
  deliveryAddress: row.delivery_address,
  estimatedDeliveryDate: row.estimated_delivery_date,
  stockDiscounted: row.stock_discounted,
  createdAt: row.created_at,
  updatedAt: row.updated_at,
  canceledAt: row.canceled_at,
  items,
  creditNotes: row.credit_notes ?? [],
  totalCredited: Number(row.total_credited ?? 0),
  netTotal: Number(row.net_total ?? row.total),
  hasCreditNotes: Number(row.total_credited ?? 0) > 0,
  appliedPromotions: row.applied_promotions ?? [],
});

const mapItem = (row) => ({
  id: row.id,
  orderId: row.order_id,
  productId: row.product_id,
  productVariantId: row.product_variant_id ?? null,
  productCode: row.product_code,
  productName: row.product_name_snapshot ?? row.product_name,
  variantNameSnapshot: row.variant_name_snapshot ?? null,
  quantity: Number(row.quantity),
  unitMeasure: row.unit_measure,
  unitPrice: Number(row.unit_price),
  discountAmount: Number(row.discount_amount),
  discountType: row.discount_type ?? 'amount',
  discountValue: Number(row.discount_value ?? 0),
  originalUnitPrice: Number(row.original_unit_price ?? row.unit_price),
  promotionId: row.promotion_id ?? null,
  appliedPromotions: row.applied_promotions ?? [],
  subtotal: Number(row.subtotal),
  cost: row.cost == null ? null : Number(row.cost),
  estimatedMargin: Number(row.estimated_margin),
});

export class OrderService {
  async list({ filters, pagination, role, userId }) {
    const { rows, total, statusCounts } = await orderRepository.list({ filters, pagination, role, userId });
    const countsByStatus = Object.fromEntries(['pendiente', 'preparado', 'en_reparto', 'entregado', 'cancelado'].map((s) => [s, 0]));
    for (const row of statusCounts ?? []) {
      countsByStatus[row.status] = Number(row.total ?? 0);
    }
    return {
      total,
      page: pagination.page,
      limit: pagination.limit,
      totalPages: Math.max(1, Math.ceil(Number(total) / Number(pagination.limit || 1))),
      countsByStatus,
      items: rows.map((r) => mapOrder(r)),
    };
  }

  async listPendingDelivery({ zoneId, role, userId }) {
    const rows = await orderRepository.listPendingDelivery({ zoneId, role, userId });
    return rows.map((r) => mapOrder(r));
  }

  async getById(id, role, userId) {
    const order = await orderRepository.findById(id);
    if (!order) throw new AppError('Pedido no encontrado.', 404);
    this.ensureAccess(order, role, userId);
    const [items, creditSummary, creditNotes] = await Promise.all([
      orderRepository.listItems(id),
      orderRepository.getCreditNotesSummary(id),
      orderRepository.listCreditNotesByOrder(id),
    ]);
    const enriched = {
      ...order,
      total_credited: Number(creditSummary.total_credited ?? 0),
      net_total: Number(order.total) - Number(creditSummary.total_credited ?? 0),
      credit_notes: creditNotes.map((note) => ({
        id: note.id,
        number: Number(note.number),
        reason: note.reason,
        totalAmount: Number(note.total_amount),
        createdAt: note.created_at,
      })),
    };
    const apps = await orderRepository.listOrderPromotionApplications(id);
    return mapOrder({ ...enriched, applied_promotions: apps }, items.map(mapItem));
  }

  async create(payload, user) {
    if (!payload.clientId) throw new AppError('Debe seleccionar un cliente.', 400);
    if (!payload.items?.length) throw new AppError('Debe incluir al menos un producto.', 400);

    const client = await this.loadClient(payload.clientId);
    const normalizedPayload = { ...payload, paymentTerms: payload.paymentTerms ?? 'contado' };
    const computed = await this.computeTotals(normalizedPayload);
    const orderId = await orderRepository.createOrder(client, normalizedPayload, user.sub, computed);
    await orderRepository.replaceOrderPromotionApplications(orderId, computed.appliedPromotions ?? []);
    return this.getById(orderId, user.role, user.sub);
  }

  async update(id, payload, user) {
    const existing = await orderRepository.findById(id);
    if (!existing) throw new AppError('Pedido no encontrado.', 404);
    this.ensureAccess(existing, user.role, user.sub);

    if (!editableStatuses.includes(existing.status)) {
      throw new AppError('Solo se pueden editar pedidos pendientes.', 409);
    }
    if (!payload.items?.length) throw new AppError('Debe incluir al menos un producto.', 400);

    const client = await this.loadClient(payload.clientId);
    const normalizedPayload = { ...payload, paymentTerms: payload.paymentTerms ?? existing.payment_terms ?? 'contado' };
    const computed = await this.computeTotals(normalizedPayload);
    await orderRepository.updatePendingOrder(id, client, normalizedPayload, computed);
    await orderRepository.replaceOrderPromotionApplications(id, computed.appliedPromotions ?? []);

    if (existing.status === 'entregado' && existing.payment_terms === 'cuenta_corriente') {
      await accountService.reverseOrderDebt({ orderId: id, clientId: existing.client_id, total: Number(existing.total), userId: user.sub });
    }

    return this.getById(id, user.role, user.sub);
  }

  async recalculatePromotions(id, user) {
    const existing = await orderRepository.findById(id);
    if (!existing) throw new AppError('Pedido no encontrado.', 404);
    this.ensureAccess(existing, user.role, user.sub);
    if (!editableStatuses.includes(existing.status)) throw new AppError('Solo se pueden recalcular promociones en pedidos pendientes.', 409);
    const currentItems = await orderRepository.listItems(id);
    const payload = {
      clientId: existing.client_id,
      paymentTerms: existing.payment_terms ?? 'contado',
      notes: existing.notes,
      deliveryAddress: existing.delivery_address,
      estimatedDeliveryDate: existing.estimated_delivery_date,
      items: currentItems.map((i) => ({ productId: i.product_id, productVariantId: i.product_variant_id, quantity: Number(i.quantity), discountType: 'amount', discountValue: 0 })),
    };
    const client = await this.loadClient(existing.client_id);
    const computed = await this.computeTotals(payload);
    await orderRepository.updatePendingOrder(id, client, payload, computed);
    await orderRepository.replaceOrderPromotionApplications(id, computed.appliedPromotions ?? []);
    return this.getById(id, user.role, user.sub);
  }

  async cancel(id, user) {
    const existing = await orderRepository.findById(id);
    if (!existing) throw new AppError('Pedido no encontrado.', 404);
    this.ensureAccess(existing, user.role, user.sub);

    if (existing.status === 'cancelado') return this.getById(id, user.role, user.sub);

    if (existing.stock_discounted) await orderRepository.restoreStock(id);
    if (existing.payment_terms === 'cuenta_corriente') {
      await accountService.reverseOrderDebt({ orderId: id, clientId: existing.client_id, total: Number(existing.total), userId: user.sub });
    }
    if (existing.stock_discounted) {
      const items = await orderRepository.listItems(id);
      await stockService.applyOrderStockMovement(id, items, user.sub, 'devolucion', 'Reversión por cancelación de pedido');
    }

    await orderRepository.cancel(id);
    return this.getById(id, user.role, user.sub);
  }

  async archive(id, user, reason = null) {
    const existing = await orderRepository.findById(id);
    if (!existing) throw new AppError('Pedido no encontrado.', 404);
    this.ensureAccess(existing, user.role, user.sub);

    if (user.role === 'vendedor' && existing.seller_id !== user.sub) {
      throw new AppError('Solo podés eliminar tus propios pedidos.', 403);
    }

    if (!['pendiente', 'preparado', 'entregado'].includes(existing.status)) {
      throw new AppError('Solo se pueden archivar pedidos pendientes, preparados o entregados.', 409);
    }
    await orderRepository.archive(id, user.sub, reason);
    return { id, archived: true };
  }

  async changeStatus(id, status, user) {
    const existing = await orderRepository.findById(id);
    if (!existing) throw new AppError('Pedido no encontrado.', 404);
    this.ensureAccess(existing, user.role, user.sub);
    if (terminalStatuses.includes(existing.status)) throw new AppError('No se puede cambiar estado de pedidos entregados o cancelados.', 409);
    if (status !== 'preparado') {
      throw new AppError('Desde Pedidos solo se permite pasar a preparado. Los estados de reparto se gestionan en Entregas.', 409);
    }

    if (stockCommitStatuses.includes(status) && !existing.stock_discounted) {
      await this.ensureStockForOrder(id);
      const items = await orderRepository.listItems(id);
      await stockService.applyOrderStockMovement(id, items, user.sub, 'salida', `Descuento por cambio de estado a ${status}`);
      await pool.query('UPDATE orders SET stock_discounted = TRUE, updated_at = NOW() WHERE id = $1', [id]);
    }

    await orderRepository.updateStatus(id, status);
    return this.getById(id, user.role, user.sub);
  }

  async validateStockForOrder(orderId, role, userId) {
    const order = await orderRepository.findById(orderId);
    if (!order) throw new AppError('Pedido no encontrado.', 404);
    this.ensureAccess(order, role, userId);

    const items = await orderRepository.listItems(orderId);
    const validationItems = [];

    for (const item of items) {
      const availableStock = await this.resolveAvailableStock(item.product_id, item.product_variant_id);
      const requiredQuantity = Number(item.quantity);

      validationItems.push({
        productId: item.product_id,
        productName: item.product_name,
        requiredQuantity,
        availableStock,
        hasStock: availableStock >= requiredQuantity,
      });
    }

    return {
      hasInsufficientStock: validationItems.some((item) => !item.hasStock),
      items: validationItems,
    };
  }

  async ensureStockForOrder(orderId) {
    const items = await orderRepository.listItems(orderId);
    for (const item of items) {
      const availableStock = await this.resolveAvailableStock(item.product_id, item.product_variant_id);
      if (availableStock < Number(item.quantity)) {
        const variantName = item.variant_name_snapshot ?? null;
        const productName = variantName ? `${item.product_name} - ${variantName}` : item.product_name;
        throw new AppError(
          `Stock insuficiente para ${productName}. Disponible: ${availableStock}.`,
          409,
          { code: 'INSUFFICIENT_STOCK', productName: item.product_name, variantName, availableStock },
        );
      }
    }
  }

  async computeTotals(payload) {
    const productIds = payload.items.map((i) => i.productId);
    const variantIds = payload.items.map((i) => i.productVariantId).filter(Boolean);
    const products = await orderRepository.findProductsByIds(productIds);
    const variants = variantIds.length ? await orderRepository.findVariantsByIds(variantIds) : [];
    const map = new Map(products.map((p) => [p.id, p]));
    const variantMap = new Map(variants.map((v) => [v.id, v]));

    const items = payload.items.map((raw) => {
      const quantity = Number(raw.quantity);
      if (!Number.isFinite(quantity) || quantity <= 0) throw new AppError('Todas las cantidades deben ser mayores a cero.', 400);

      const product = map.get(raw.productId);
      if (!product || !product.is_active) throw new AppError('Hay productos inexistentes o inactivos en el pedido.', 400);

      const hasVariants = product.has_variants === true;
      const variantId = raw.productVariantId ?? null;
      let variant = null;

      if (hasVariants && !variantId) {
        throw new AppError(`Debe seleccionar variante para ${product.name}.`, 400);
      }

      if (variantId) {
        variant = variantMap.get(variantId);
        if (!variant || variant.product_id !== product.id || variant.is_active !== true) {
          throw new AppError(`La variante seleccionada no es válida para ${product.name}.`, 400);
        }
      }

      const unitPrice = Number(variant?.price ?? product.wholesale_price ?? 0);
      const discountType = raw.discountType ?? 'amount';
      const discountValue = Number(raw.discountValue ?? raw.discountAmount ?? 0);
      const discountAmount = discountType === 'percentage'
        ? Math.max(0, (unitPrice * quantity * discountValue) / 100)
        : Math.max(0, discountValue);
      const subtotal = Math.max(0, unitPrice * quantity - discountAmount);
      const unitCost = Number(variant?.cost ?? product.cost ?? 0);
      const estimatedMargin = subtotal - (unitCost * quantity);

      return {
        productId: product.id,
        productVariantId: variant?.id ?? null,
        productCode: variant?.internal_code ?? product.internal_code,
        productName: variant ? `${product.name} - ${variant.name}` : product.name,
        productNameSnapshot: product.name,
        variantNameSnapshot: variant?.name ?? null,
        quantity,
        unitMeasure: product.unit_measure,
        unitPrice,
        discountType,
        discountValue,
        discountAmount,
        subtotal,
        cost: unitCost,
        estimatedMargin,
      };
    });

    const stockValidItems = [];
    for (const item of items) {
      const availableStock = await this.resolveAvailableStock(item.productId, item.productVariantId);
      if (availableStock >= Number(item.quantity)) stockValidItems.push(item);
    }
    if (!stockValidItems.length) throw new AppError('Ninguna línea del pedido tiene stock disponible.', 409);

    const dup = new Set();
    const uniqueItems = [];
    for (const i of stockValidItems) {
      const key = `${i.productId}:${i.productVariantId ?? 'base'}`;
      if (dup.has(key)) throw new AppError('No se permiten líneas duplicadas de producto/variante.', 400);
      dup.add(key);
      uniqueItems.push(i);
    }

    const promotableItems = uniqueItems.map((i) => ({
      product_id: i.productId,
      variant_id: i.productVariantId,
      quantity: i.quantity,
      unit_price: i.unitPrice,
    }));
    const promoPreview = await promotionService.preview({ client_id: payload.clientId, zone_id: null, items: promotableItems });
    const byKey = new Map(promoPreview.items.map((x) => [`${x.product_id}:${x.variant_id ?? 'base'}`, x]));
    for (const item of uniqueItems) {
      const key = `${item.productId}:${item.productVariantId ?? 'base'}`;
      const p = byKey.get(key);
      item.originalUnitPrice = item.unitPrice;
      item.unitPrice = p?.final_unit_price ?? item.unitPrice;
      item.discountAmount = p?.discount_amount ?? 0;
      item.appliedPromotions = p?.applied_promotions ?? [];
      item.promotionId = item.appliedPromotions[0]?.promotion_id ?? null;
      item.subtotal = Math.max(0, item.unitPrice * item.quantity);
    }

    const subtotal = uniqueItems.reduce((acc, i) => acc + (i.originalUnitPrice ?? i.unitPrice) * i.quantity, 0);
    const discountTotal = Number(promoPreview.discount_total ?? 0);
    const taxTotal = 0;
    const total = Math.max(0, subtotal - discountTotal);
    const estimatedMargin = uniqueItems.reduce((acc, i) => acc + ((i.unitPrice * i.quantity) - (i.cost * i.quantity)), 0);

    return { items: uniqueItems, subtotal, discountTotal, taxTotal, total, estimatedMargin, appliedPromotions: promoPreview.applied_promotions ?? [] };
  }


  async resolveAvailableStock(productId, productVariantId) {
    if (productVariantId) {
      const { rows: variantRows } = await pool.query('SELECT stock FROM product_variants WHERE id = $1 LIMIT 1', [productVariantId]);
      const variantStock = variantRows[0]?.stock;
      if (variantStock != null) return Number(variantStock);
    }
    const { rows } = await pool.query('SELECT stock_current, has_variants FROM products WHERE id = $1 LIMIT 1', [productId]);
    if (rows[0]?.has_variants === true) {
      return 0;
    }
    return Number(rows[0]?.stock_current ?? 0);
  }

  async loadClient(clientId) {
    const { rows } = await pool.query('SELECT id, address_line FROM clients WHERE id = $1 LIMIT 1', [clientId]);
    const client = rows[0];
    if (!client) throw new AppError('Cliente no encontrado.', 404);
    return client;
  }

  ensureAccess(order, role, userId) {
    if (role === 'admin') return;
    if (role === 'vendedor' && order.seller_id === userId) return;
    if (role === 'repartidor' && order.assigned_delivery_user_id === userId) return;
    throw new AppError('No autorizado para acceder a este pedido.', 403);
  }
}

export const orderService = new OrderService();
