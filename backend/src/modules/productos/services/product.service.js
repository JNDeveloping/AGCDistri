import { AppError } from '../../../errors/app-error.js';
import { productRepository } from '../repositories/product.repository.js';

const computeMargin = (cost, wholesalePrice) => {
  if (!cost || cost <= 0) {
    return null;
  }

  return Number((((wholesalePrice - cost) / cost) * 100).toFixed(2));
};

const formatProduct = (row) => ({
  id: row.id,
  internalCode: row.internal_code,
  name: row.name,
  shortDescription: row.short_description,
  longDescription: row.long_description,
  brand: row.brand,
  category: row.category,
  segment: row.segment,
  barcode: row.barcode,
  unitMeasure: row.unit_measure,
  presentation: row.presentation,
  cost: Number(row.cost),
  wholesalePrice: Number(row.wholesale_price),
  retailPrice: row.retail_price == null ? null : Number(row.retail_price),
  marginPercentage: row.margin_percentage == null ? null : Number(row.margin_percentage),
  stockCurrent: Number(row.stock_current),
  stockMinimum: Number(row.stock_minimum),
  isActive: row.is_active,
  isFeatured: row.is_featured,
  imageUrl: row.image_url,
  taxRate: row.tax_rate == null ? null : Number(row.tax_rate),
  createdAt: row.created_at,
  updatedAt: row.updated_at,
  deactivatedAt: row.deactivated_at,
  lowStock: Number(row.stock_current) <= Number(row.stock_minimum),
});

const basicProduct = (p) => ({
  id: p.id,
  internalCode: p.internalCode,
  name: p.name,
  shortDescription: p.shortDescription,
  brand: p.brand,
  category: p.category,
  segment: p.segment,
  presentation: p.presentation,
  stockCurrent: p.stockCurrent,
  stockMinimum: p.stockMinimum,
  isActive: p.isActive,
  lowStock: p.lowStock,
});

export class ProductService {
  async create(payload) {
    const duplicated = await productRepository.findDuplicated({
      internalCode: payload.internalCode,
      barcode: payload.barcode ?? null,
    });

    if (duplicated) {
      throw new AppError('Ya existe producto con ese código interno o código de barras.', 409);
    }

    const marginPercentage = payload.marginPercentage ?? computeMargin(payload.cost, payload.wholesalePrice);
    const created = await productRepository.create({ ...payload, marginPercentage });
    return formatProduct(created);
  }

  async list({ q, isActive, lowStock, page, limit, role }) {
    const { rows, total } = await productRepository.list({ q, isActive, lowStock, page, limit });
    const items = rows.map((row) => formatProduct(row));

    return {
      total,
      page,
      limit,
      items: role === 'repartidor' ? items.map(basicProduct) : items,
    };
  }

  async getById(id, role) {
    const row = await productRepository.findById(id);
    if (!row) {
      throw new AppError('Producto no encontrado.', 404);
    }

    const product = formatProduct(row);
    return role === 'repartidor' ? basicProduct(product) : product;
  }

  async update(id, payload) {
    const existing = await productRepository.findById(id);
    if (!existing) {
      throw new AppError('Producto no encontrado.', 404);
    }

    const internalCode = payload.internalCode ?? existing.internal_code;
    const barcode = payload.barcode ?? existing.barcode;

    const duplicated = await productRepository.findDuplicated({ internalCode, barcode, ignoreId: id });
    if (duplicated) {
      throw new AppError('Ya existe producto con ese código interno o código de barras.', 409);
    }

    const cost = payload.cost ?? Number(existing.cost);
    const wholesalePrice = payload.wholesalePrice ?? Number(existing.wholesale_price);
    const marginPercentage = payload.marginPercentage ?? computeMargin(cost, wholesalePrice);

    const updated = await productRepository.update(id, { ...payload, marginPercentage });
    return formatProduct(updated);
  }

  async deactivate(id) {
    const row = await productRepository.deactivate(id);
    if (!row) {
      throw new AppError('Producto no encontrado.', 404);
    }

    return formatProduct(row);
  }
}

export const productService = new ProductService();
