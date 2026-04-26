import { AppError } from '../../../errors/app-error.js';
import { productVariantRepository } from '../repositories/product-variant.repository.js';

const mapVariant = (row, product = null) => ({
  id: row.id,
  productId: row.product_id,
  name: row.name,
  internalCode: row.internal_code,
  barcode: row.barcode,
  price: row.price == null ? null : Number(row.price),
  cost: row.cost == null ? null : Number(row.cost),
  stock: row.stock == null ? null : Number(row.stock),
  active: row.is_active === true,
  createdAt: row.created_at,
  updatedAt: row.updated_at,
  effectivePrice: row.price == null ? (product ? Number(product.wholesale_price ?? 0) : null) : Number(row.price),
  effectiveStock: row.stock == null ? (product ? Number(product.stock_current ?? 0) : null) : Number(row.stock),
});

export class ProductVariantService {
  async listByProduct(productId) {
    const product = await productVariantRepository.findProduct(productId);
    if (!product) throw new AppError('Producto no encontrado.', 404);
    const rows = await productVariantRepository.listByProduct(productId);
    return rows.map((row) => mapVariant(row, product));
  }

  async create(productId, payload) {
    const product = await productVariantRepository.findProduct(productId);
    if (!product) throw new AppError('Producto no encontrado.', 404);

    const duplicated = await productVariantRepository.findByProductAndName(productId, payload.name);
    if (duplicated) throw new AppError('Ya existe una variante con ese nombre para el producto.', 409);

    const saved = await productVariantRepository.create({ ...payload, productId });
    return mapVariant(saved, product);
  }

  async update(id, payload) {
    const existing = await productVariantRepository.findById(id);
    if (!existing) throw new AppError('Variante no encontrada.', 404);

    const duplicated = await productVariantRepository.findByProductAndName(existing.product_id, payload.name, id);
    if (duplicated) throw new AppError('Ya existe una variante con ese nombre para el producto.', 409);

    const updated = await productVariantRepository.update(id, payload);
    const product = await productVariantRepository.findProduct(existing.product_id);
    return mapVariant(updated, product);
  }

  async deactivate(id) {
    const row = await productVariantRepository.setActive(id, false);
    if (!row) throw new AppError('Variante no encontrada.', 404);
    const product = await productVariantRepository.findProduct(row.product_id);
    return mapVariant(row, product);
  }

  async activate(id) {
    const row = await productVariantRepository.setActive(id, true);
    if (!row) throw new AppError('Variante no encontrada.', 404);
    const product = await productVariantRepository.findProduct(row.product_id);
    return mapVariant(row, product);
  }

  async remove(id) {
    const removed = await productVariantRepository.remove(id);
    if (!removed) throw new AppError('Variante no encontrada.', 404);
    return { id };
  }
}

export const productVariantService = new ProductVariantService();

