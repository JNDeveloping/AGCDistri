import { AppError } from '../../../errors/app-error.js';
import { pool } from '../../../database/pool.js';
import { accountService } from '../../accounts/services/account.service.js';
import { stockService } from '../../stock/services/stock.service.js';
import { orderRepository } from '../repositories/order.repository.js';

const editableStatuses = ['pendiente'];
const terminalStatuses = ['entregado', 'cancelado'];
const stockCommitStatuses = ['confirmado', 'preparado'];

const mapOrder = (row, items = []) => ({
  id: row.id,
  orderNumber: row.order_number,
  clientId: row.client_id,
  clientName: row.client_name,
  clientPhone: row.client_phone,
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
  subtotal: Number(row.subtotal),
  cost: row.cost == null ? null : Number(row.cost),
  estimatedMargin: Number(row.estimated_margin),
});

export class OrderService {
  async list({ filters, pagination, role, userId }) {
    const { rows, total } = await orderRepository.list({ filters, pagination, role, userId });
    return { total, page: pagination.page, limit: pagination.limit, items: rows.map((r) => mapOrder(r)) };
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
    return mapOrder(enriched, items.map(mapItem));
  }

  async create(payload, user) {
    if (!payload.clientId) throw new AppError('Debe seleccionar un cliente.', 400);
    if (!payload.items?.length) throw new AppError('Debe incluir al menos un producto.', 400);

    const client = await this.loadClient(payload.clientId);
    const normalizedPayload = { ...payload, paymentTerms: payload.paymentTerms ?? 'contado' };
    const computed = await this.computeTotals(normalizedPayload);
    const orderId = await orderRepository.createOrder(client, normalizedPayload, user.sub, computed);
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

    if (existing.status === 'entregado' && existing.payment_terms === 'cuenta_corriente') {
      await accountService.reverseOrderDebt({ orderId: id, clientId: existing.client_id, total: Number(existing.total), userId: user.sub });
    }

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

  async remove(id, user) {
    const existing = await orderRepository.findById(id);
    if (!existing) throw new AppError('Pedido no encontrado.', 404);
    this.ensureAccess(existing, user.role, user.sub);

    if (user.role === 'vendedor' && existing.seller_id !== user.sub) {
      throw new AppError('Solo podés eliminar tus propios pedidos.', 403);
    }

    if (existing.status !== 'pendiente') {
      throw new AppError('Solo se pueden eliminar pedidos pendientes.', 409);
    }

    const hasAssociatedMovements = await orderRepository.hasAccountOrStockMovements(id);
    if (hasAssociatedMovements || existing.stock_discounted || existing.payment_terms === 'cuenta_corriente') {
      throw new AppError('No se puede eliminar este pedido porque tiene movimientos asociados. Podés cancelarlo.', 409);
    }

    await orderRepository.remove(id);
    return { id };
  }

  async changeStatus(id, status, user) {
    const existing = await orderRepository.findById(id);
    if (!existing) throw new AppError('Pedido no encontrado.', 404);
    this.ensureAccess(existing, user.role, user.sub);
    if (terminalStatuses.includes(existing.status)) throw new AppError('No se puede cambiar estado de pedidos entregados o cancelados.', 409);
    if (status === 'cancelado') return this.cancel(id, user);

    if (stockCommitStatuses.includes(status) && !existing.stock_discounted) {
      await this.ensureStockForOrder(id);
      const items = await orderRepository.listItems(id);
      await stockService.applyOrderStockMovement(id, items, user.sub, 'salida', `Descuento por cambio de estado a ${status}`);
      await pool.query('UPDATE orders SET stock_discounted = TRUE, updated_at = NOW() WHERE id = $1', [id]);
    }

    await orderRepository.updateStatus(id, status);
    if (status === 'entregado' && existing.payment_terms === 'cuenta_corriente') {
      await accountService.applyOrderDebt({
        orderId: id,
        clientId: existing.client_id,
        total: Number(existing.total),
        userId: user.sub,
      });
    }
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
        throw new AppError(
          `Stock insuficiente para ${item.product_name}. Disponible: ${availableStock}.`,
          409,
          { code: 'INSUFFICIENT_STOCK', productName: item.product_name, availableStock },
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

    const subtotal = items.reduce((acc, i) => acc + i.subtotal, 0);
    const discountTotal = Number(payload.discountTotal ?? 0);
    const taxTotal = 0;
    const total = Math.max(0, subtotal - discountTotal);
    const estimatedMargin = items.reduce((acc, i) => acc + i.estimatedMargin, 0) - discountTotal;

    return { items, subtotal, discountTotal, taxTotal, total, estimatedMargin };
  }


  async resolveAvailableStock(productId, productVariantId) {
    if (productVariantId) {
      const { rows: variantRows } = await pool.query('SELECT stock FROM product_variants WHERE id = $1 LIMIT 1', [productVariantId]);
      const variantStock = variantRows[0]?.stock;
      if (variantStock != null) return Number(variantStock);
    }
    const { rows } = await pool.query('SELECT stock_current FROM products WHERE id = $1 LIMIT 1', [productId]);
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
