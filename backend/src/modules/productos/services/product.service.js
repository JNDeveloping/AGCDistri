import { AppError } from '../../../errors/app-error.js';
import { pool } from '../../../database/pool.js';
import { productRepository } from '../repositories/product.repository.js';
import { productCategoryRepository } from '../../product-categories/repositories/product-category.repository.js';

const computeMargin = (cost, wholesalePrice) => {
  if (!cost || cost <= 0 || !wholesalePrice || wholesalePrice <= 0) {
    return null;
  }

  return Number((((wholesalePrice - cost) / cost) * 100).toFixed(2));
};

const applyRounding = (value, multiple) => {
  if (!multiple || multiple <= 0) return value;
  return Math.ceil(value / multiple) * multiple;
};


const ensureActiveCategory = async (categoryId) => {
  if (!categoryId) return;
  const category = await productCategoryRepository.findById(categoryId);
  if (!category) {
    throw new AppError('La categoría seleccionada no existe.', 400);
  }
  if (!category.is_active) {
    throw new AppError('La categoría seleccionada está inactiva.', 400);
  }
};

const getPricingSettings = async () => {
  const { rows } = await pool.query(
    'SELECT default_profit_percentage, price_rounding_enabled, price_rounding_multiple FROM company_settings WHERE id = 1 LIMIT 1',
  );

  if (!rows[0]) {
    return {
      defaultProfitPercentage: 45,
      priceRoundingEnabled: true,
      priceRoundingMultiple: 10,
    };
  }

  return {
    defaultProfitPercentage: Number(rows[0].default_profit_percentage ?? 45),
    priceRoundingEnabled: rows[0].price_rounding_enabled === true,
    priceRoundingMultiple: Number(rows[0].price_rounding_multiple ?? 10),
  };
};

const formatProduct = (row, role) => {
  const base = {
    id: row.id,
    internalCode: row.internal_code,
    name: row.name,
    shortDescription: row.short_description,
    longDescription: row.long_description,
    brand: row.brand,
    barcode: row.barcode,
    unitMeasure: row.unit_measure,
    salePrice: row.wholesale_price == null ? null : Number(row.wholesale_price),
    stockCurrent: row.stock_current == null ? 0 : Number(row.stock_current),
    stockMinimum: row.stock_minimum == null ? 0 : Number(row.stock_minimum),
    isActive: row.is_active,
    hasVariants: row.has_variants === true,
    isFeatured: row.is_featured,
    imageUrl: row.image_url,
    taxRate: row.tax_rate == null ? null : Number(row.tax_rate),
    notes: row.notes,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    deactivatedAt: row.deactivated_at,
    categoryId: row.category_id,
    categoryName: row.category_name,
    categoryIsActive: row.category_is_active,
    lowStock: Number(row.stock_current ?? 0) <= Number(row.stock_minimum ?? 0),
  };

  if (role === 'admin') {
    return {
      ...base,
      cost: row.cost == null ? null : Number(row.cost),
      marginPercentage: row.margin_percentage == null ? null : Number(row.margin_percentage),
    };
  }

  if (role === 'vendedor') {
    return {
      ...base,
      cost: null,
      marginPercentage: null,
    };
  }

  return {
    id: base.id,
    internalCode: base.internalCode,
    name: base.name,
    shortDescription: base.shortDescription,
    unitMeasure: base.unitMeasure,
    salePrice: base.salePrice,
    stockCurrent: base.stockCurrent,
    stockMinimum: base.stockMinimum,
    isActive: base.isActive,
    lowStock: base.lowStock,
    categoryName: base.categoryName,
  };
};

export class ProductService {
  async create(payload) {
    const hasVariants = payload.hasVariants === true;
    const duplicated = await productRepository.findDuplicated({
      internalCode: payload.internalCode,
      barcode: payload.barcode,
    });

    if (duplicated) {
      throw new AppError('Ya existe producto con ese código interno o código de barras.', 409);
    }

    await ensureActiveCategory(payload.categoryId ?? null);

    if (!hasVariants) {
      const inputSalePrice = payload.salePrice ?? payload.wholesalePrice;
      if (inputSalePrice == null || Number(inputSalePrice) <= 0) {
        throw new AppError('El precio de venta es obligatorio para productos sin variantes.', 400);
      }
    }

    const settings = await getPricingSettings();
    const inputSalePrice = payload.salePrice ?? payload.wholesalePrice;
    const effectiveWholesalePrice = hasVariants
      ? (inputSalePrice ?? null)
      : inputSalePrice
      ?? (payload.cost != null
        ? applyRounding(
            payload.cost + (payload.cost * settings.defaultProfitPercentage) / 100,
            settings.priceRoundingEnabled ? settings.priceRoundingMultiple : 0,
          )
        : null);
    const marginPercentage = payload.marginPercentage ?? computeMargin(payload.cost, effectiveWholesalePrice);
    const created = await productRepository.create({
      ...payload,
      wholesalePrice: effectiveWholesalePrice,
      marginPercentage,
      shortDescription: payload.shortDescription ?? null,
      stockCurrent: hasVariants ? 0 : (payload.stockCurrent ?? 0),
      stockMinimum: hasVariants ? 0 : (payload.stockMinimum ?? 0),
    });
    return formatProduct(created, 'admin');
  }


  async autocomplete({ q, limit }) {
    const rows = await productRepository.autocomplete({ q: q?.trim() ?? '', limit: limit ?? 20 });

    return {
      total: rows.length,
      items: rows.map((row) => ({
        productId: row.product_id,
        productName: row.product_name,
        internalCode: row.product_internal_code,
        barcode: row.product_barcode,
        brand: row.brand,
        categoryName: row.category_name,
        hasVariants: row.has_variants === true,
        variantId: row.variant_id,
        variantName: row.variant_name,
        variantInternalCode: row.variant_internal_code,
        variantBarcode: row.variant_barcode,
        effectivePrice: Number(row.variant_id ? row.variant_price ?? 0 : row.product_price ?? 0),
        effectiveStock: Number(row.variant_id ? row.variant_stock ?? 0 : row.product_stock ?? 0),
      })),
    };
  }

  async list({ q, isActive, lowStock, page, limit, role }) {
    const { rows, total } = await productRepository.list({ q, isActive, lowStock, page, limit });
    return {
      total,
      page,
      limit,
      items: rows.map((row) => formatProduct(row, role)),
    };
  }

  async getById(id, role) {
    const row = await productRepository.findById(id);
    if (!row) {
      throw new AppError('Producto no encontrado.', 404);
    }

    return formatProduct(row, role);
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

    if (payload.categoryId !== undefined) {
      await ensureActiveCategory(payload.categoryId);
    }

    const hasVariants = payload.hasVariants ?? (existing.has_variants === true);
    const cost = payload.cost ?? Number(existing.cost ?? 0);
    const settings = await getPricingSettings();
    const storedWholesale = Number(existing.wholesale_price ?? 0);
    const suggestedWholesale = applyRounding(
      cost + (cost * settings.defaultProfitPercentage) / 100,
      settings.priceRoundingEnabled ? settings.priceRoundingMultiple : 0,
    );
    const inputSalePrice = payload.salePrice ?? payload.wholesalePrice;
    if (!hasVariants && inputSalePrice == null && storedWholesale <= 0) {
      throw new AppError('El precio de venta es obligatorio para productos sin variantes.', 400);
    }
    const wholesalePrice = hasVariants
      ? (inputSalePrice ?? existing.wholesale_price ?? null)
      : (inputSalePrice ?? (storedWholesale > 0 ? storedWholesale : suggestedWholesale));
    const marginPercentage = payload.marginPercentage ?? computeMargin(cost, wholesalePrice);

    const patch = {
      ...payload,
      wholesalePrice,
      marginPercentage,
    };
    if (hasVariants) {
      patch.stockCurrent = 0;
      patch.stockMinimum = 0;
    }

    const updated = await productRepository.update(id, patch);

    return formatProduct(updated, 'admin');
  }

  async deactivate(id) {
    const row = await productRepository.deactivate(id);
    if (!row) {
      throw new AppError('Producto no encontrado.', 404);
    }

    return formatProduct(row, 'admin');
  }
}

export const productService = new ProductService();
