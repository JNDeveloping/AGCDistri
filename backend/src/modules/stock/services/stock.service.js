import { AppError } from '../../../errors/app-error.js';
import { stockRepository } from '../repositories/stock.repository.js';

const affectsDecrease = new Set(['salida', 'merma', 'transferencia']);
const mapMovement = (row) => ({
  id: row.id,
  productId: row.product_id,
  productName: row.product_name,
  movementType: row.movement_type,
  productVariantId: row.product_variant_id ?? null,
  quantity: Number(row.quantity),
  previousStock: Number(row.previous_stock),
  newStock: Number(row.new_stock),
  reason: row.reason,
  notes: row.notes,
  userId: row.user_id,
  userName: row.user_name,
  referenceType: row.reference_type,
  referenceId: row.reference_id,
  sourceLocation: row.source_location,
  destinationLocation: row.destination_location,
  createdAt: row.created_at,
});

export class StockService {
  async listStock(filters) {
    const rows = await stockRepository.listStock(filters);
    return rows.map((row) => ({
      productId: row.id,
      internalCode: row.internal_code,
      barcode: row.barcode,
      name: row.name,
      categoryName: row.category_name,
      stockCurrent: Number(row.stock_current),
      stockMinimum: Number(row.stock_minimum),
      status: Number(row.stock_current) <= 0 ? 'sin_stock' : Number(row.stock_current) <= Number(row.stock_minimum) ? 'stock_bajo' : 'normal',
    }));
  }

  async getProductStock(productId) {
    const product = await stockRepository.findProduct(productId);
    if (!product) throw new AppError('Producto no encontrado.', 404);
    return {
      productId: product.id,
      internalCode: product.internal_code,
      barcode: product.barcode,
      name: product.name,
      stockCurrent: Number(product.stock_current),
      stockMinimum: Number(product.stock_minimum),
      isActive: product.is_active,
    };
  }

  async listMovements(filters) {
    const rows = await stockRepository.listMovements(filters);
    return rows.map(mapMovement);
  }

  async createMovement(payload, user) {
    const quantity = Number(payload.quantity);
    if (!Number.isFinite(quantity) || quantity <= 0) throw new AppError('La cantidad debe ser mayor a cero.', 400);

    const product = await stockRepository.findProduct(payload.productId);
    if (!product) throw new AppError('Producto no encontrado.', 404);

    const variant = payload.productVariantId ? await stockRepository.findVariant(payload.productVariantId) : null;
    if (payload.productVariantId && (!variant || variant.product_id !== product.id)) {
      throw new AppError('Variante no encontrada para el producto seleccionado.', 404);
    }

    const previous = variant && variant.stock != null ? Number(variant.stock) : Number(product.stock_current);
    const isDecrease = affectsDecrease.has(payload.movementType);
    const next = isDecrease ? previous - quantity : previous + quantity;
    if (next < 0) throw new AppError('Stock insuficiente para realizar la salida.', 409);

    if (variant && variant.stock != null) {
      await stockRepository.updateVariantStock(variant.id, next);
    } else {
      await stockRepository.updateStock(product.id, next);
    }

    const saved = await stockRepository.insertMovement({
      ...payload,
      productVariantId: variant?.id ?? null,
      quantity,
      previousStock: previous,
      newStock: next,
      userId: user.sub,
    });

    return mapMovement({ ...saved, product_name: variant ? `${product.name} - ${variant.name}` : product.name, user_name: user.fullName });
  }

  async adjust(payload, user) {
    if (user.role !== 'admin') throw new AppError('Solo admin puede ajustar stock manualmente.', 403);
    const product = await stockRepository.findProduct(payload.productId);
    if (!product) throw new AppError('Producto no encontrado.', 404);

    const previous = Number(product.stock_current);
    const next = Number(payload.newStock);
    if (!Number.isFinite(next) || next < 0) throw new AppError('El nuevo stock debe ser >= 0.', 400);

    await stockRepository.updateStock(product.id, next);
    const saved = await stockRepository.insertMovement({
      productId: product.id,
      movementType: 'ajuste',
      quantity: Math.abs(next - previous),
      previousStock: previous,
      newStock: next,
      reason: payload.reason,
      notes: payload.notes,
      userId: user.sub,
      referenceType: payload.referenceType,
      referenceId: payload.referenceId,
      sourceLocation: payload.sourceLocation,
      destinationLocation: payload.destinationLocation,
    });
    return mapMovement({ ...saved, product_name: product.name, user_name: user.fullName });
  }

  async applyOrderStockMovement(orderId, items, userId, movementType, reason) {
    for (const item of items) {
      const exists = await stockRepository.findMovementByReference({
        referenceType: 'order',
        referenceId: orderId,
        productId: item.product_id,
        productVariantId: item.product_variant_id,
        movementType,
      });
      if (exists) continue;

      const product = await stockRepository.findProduct(item.product_id);
      if (!product) continue;

      const variant = item.product_variant_id ? await stockRepository.findVariant(item.product_variant_id) : null;
      const trackVariantStock = variant && variant.stock != null;
      const previous = trackVariantStock ? Number(variant.stock) : Number(product.stock_current);
      const quantity = Number(item.quantity);
      const next = movementType === 'salida' ? previous - quantity : previous + quantity;
      if (next < 0) throw new AppError(`Stock insuficiente para ${item.product_name}.`, 409);

      if (trackVariantStock) {
        await stockRepository.updateVariantStock(variant.id, next);
      } else {
        await stockRepository.updateStock(item.product_id, next);
      }

      await stockRepository.insertMovement({
        productId: item.product_id,
        productVariantId: item.product_variant_id,
        movementType,
        quantity,
        previousStock: previous,
        newStock: next,
        reason,
        notes: `Pedido #${orderId}`,
        userId,
        referenceType: 'order',
        referenceId: orderId,
      });
    }
  }
}

export const stockService = new StockService();
