import { AppError } from '../../../errors/app-error.js';
import { pool } from '../../../database/pool.js';
import { productRepository } from '../repositories/product.repository.js';

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
    presentation: row.presentation,
    wholesalePrice: row.wholesale_price == null ? null : Number(row.wholesale_price),
    retailPrice: row.retail_price == null ? null : Number(row.retail_price),
    stockCurrent: row.stock_current == null ? 0 : Number(row.stock_current),
    stockMinimum: row.stock_minimum == null ? 0 : Number(row.stock_minimum),
    isActive: row.is_active,
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
    presentation: base.presentation,
    stockCurrent: base.stockCurrent,
    stockMinimum: base.stockMinimum,
    isActive: base.isActive,
    lowStock: base.lowStock,
    categoryName: base.categoryName,
  };
};

export class ProductService {
  async create(payload) {
    const duplicated = await productRepository.findDuplicated({
      internalCode: payload.internalCode,
      barcode: payload.barcode,
    });

    if (duplicated) {
      throw new AppError('Ya existe producto con ese código interno o código de barras.', 409);
    }

    const settings = await getPricingSettings();
    const effectiveWholesalePrice = payload.wholesalePrice
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
      stockCurrent: payload.stockCurrent ?? 0,
      stockMinimum: payload.stockMinimum ?? 0,
    });
    return formatProduct(created, 'admin');
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

    const cost = payload.cost ?? Number(existing.cost ?? 0);
    const settings = await getPricingSettings();
    const storedWholesale = Number(existing.wholesale_price ?? 0);
    const suggestedWholesale = applyRounding(
      cost + (cost * settings.defaultProfitPercentage) / 100,
      settings.priceRoundingEnabled ? settings.priceRoundingMultiple : 0,
    );
    const wholesalePrice = payload.wholesalePrice ?? (storedWholesale > 0 ? storedWholesale : suggestedWholesale);
    const marginPercentage = payload.marginPercentage ?? computeMargin(cost, wholesalePrice);

    const updated = await productRepository.update(id, {
      ...payload,
      marginPercentage,
    });

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
