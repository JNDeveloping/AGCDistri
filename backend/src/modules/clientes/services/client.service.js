import { AppError } from '../../../errors/app-error.js';
import { clientRepository } from '../repositories/client.repository.js';
import { zoneRepository } from '../../zones/repositories/zone.repository.js';

const formatClient = (row) => {
  if (!row) {
    return null;
  }

  return {
    id: row.id,
    internalCode: row.internal_code,
    businessName: row.business_name,
    phone: row.phone,
    email: row.email,
    taxId: row.tax_id,
    addressLine: row.address_line,
    city: row.city,
    province: row.province,
    routeZone: row.route_zone,
    zoneId: row.zone_id,
    zoneName: row.zone_name,
    notes: row.notes,
    vatCondition: row.vat_condition,
    creditLimit: Number(row.credit_limit),
    currentBalance: Number(row.current_balance),
    latitude: row.latitude == null ? null : Number(row.latitude),
    longitude: row.longitude == null ? null : Number(row.longitude),
    isActive: row.is_active,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    deactivatedAt: row.deactivated_at,
  };
};

const basicProjection = (client) => ({
  id: client.id,
  internalCode: client.internalCode,
  businessName: client.businessName,
  phone: client.phone,
  addressLine: client.addressLine,
  city: client.city,
  province: client.province,
  routeZone: client.routeZone,
  zoneName: client.zoneName,
  latitude: client.latitude,
  longitude: client.longitude,
  isActive: client.isActive,
});

export class ClientService {
  async resolveZone(zoneId, { requireActive = false } = {}) {
    if (!zoneId) {
      return null;
    }
    const zone = await zoneRepository.findById(zoneId);
    if (!zone) {
      throw new AppError('La zona/ruta seleccionada no existe.', 400);
    }
    if (requireActive && !zone.is_active) {
      throw new AppError('La zona/ruta seleccionada está inactiva.', 400);
    }
    return zone;
  }

  async create(payload) {
    const duplicated = await clientRepository.findByCodeOrTaxId({
      internalCode: payload.internalCode,
      taxId: payload.taxId ?? null,
    });

    if (duplicated) {
      throw new AppError('Ya existe un cliente con ese código interno o CUIT.', 409);
    }

    const zone = await this.resolveZone(payload.zoneId ?? null, { requireActive: true });
    const created = await clientRepository.create({
      ...payload,
      routeZone: zone?.name ?? payload.routeZone ?? 'Sin zona',
      zoneId: zone?.id ?? null,
    });
    return formatClient(created);
  }

  async list({ q, isActive, zoneId, page, limit, role }) {
    const result = await clientRepository.list({ q, isActive, zoneId, page, limit });
    const data = result.rows.map((row) => formatClient(row));
    return {
      total: result.total,
      page,
      limit,
      items: role === 'repartidor' ? data.map(basicProjection) : data,
    };
  }

  async getById(id, role) {
    const row = await clientRepository.findById(id);
    if (!row) {
      throw new AppError('Cliente no encontrado.', 404);
    }

    const client = formatClient(row);
    return role === 'repartidor' ? basicProjection(client) : client;
  }

  async update(id, payload) {
    const existing = await clientRepository.findById(id);
    if (!existing) {
      throw new AppError('Cliente no encontrado.', 404);
    }

    const mergedCode = payload.internalCode ?? existing.internal_code;
    const mergedTaxId = payload.taxId ?? existing.tax_id;

    const duplicated = await clientRepository.findByCodeOrTaxId({
      internalCode: mergedCode,
      taxId: mergedTaxId,
      ignoreId: id,
    });

    if (duplicated) {
      throw new AppError('Ya existe un cliente con ese código interno o CUIT.', 409);
    }

    const zoneId = payload.zoneId === undefined ? existing.zone_id : payload.zoneId;
    const requireActiveZone = zoneId != null && zoneId !== existing.zone_id;
    const zone = await this.resolveZone(zoneId ?? null, { requireActive: requireActiveZone });
    const updated = await clientRepository.update(id, {
      ...payload,
      routeZone: zone?.name ?? payload.routeZone ?? existing.route_zone,
      zoneId: zone?.id ?? null,
    });
    return formatClient(updated);
  }


  async getPurchaseHistory(clientId) {
    const client = await clientRepository.findById(clientId);
    if (!client) throw new AppError('Cliente no encontrado.', 404);

    const rows = await clientRepository.getPurchaseHistory(clientId);
    return rows.map((row) => ({
      productId: row.product_id,
      productName: row.product_name,
      productVariantId: row.product_variant_id,
      variantName: row.variant_name,
      lastPurchaseDate: row.last_purchase_date,
      averageQuantity: Number(row.avg_quantity ?? 0),
      lastPrice: Number(row.last_price ?? 0),
      frequency: row.frequency,
      purchaseCount: Number(row.purchase_count ?? 0),
    }));
  }

  async getSuggestedProducts(clientId) {
    const client = await clientRepository.findById(clientId);
    if (!client) throw new AppError('Cliente no encontrado.', 404);

    const rows = await clientRepository.getSuggestedProducts(clientId);
    return rows.map((row) => ({
      productId: row.product_id,
      productName: row.product_name,
      productVariantId: row.product_variant_id,
      variantName: row.variant_name,
      hasVariants: row.has_variants === true,
      stockAvailable: Number(row.stock_available ?? 0),
      currentPrice: Number(row.current_price ?? 0),
      lastPrice: row.last_price == null ? null : Number(row.last_price),
      averageQuantity: row.avg_quantity == null ? null : Number(row.avg_quantity),
      relevanceReason: row.relevance_reason,
      relevanceScore: Number(row.relevance_score ?? 0),
      zoneName: row.zone_name,
    }));
  }

  async getLastOrder(clientId) {
    const client = await clientRepository.findById(clientId);
    if (!client) throw new AppError('Cliente no encontrado.', 404);

    const order = await clientRepository.getLastOrder(clientId);
    if (!order) return { order: null, items: [] };

    const items = await clientRepository.getLastOrderItems(order.id);
    return {
      order: {
        id: order.id,
        orderNumber: Number(order.order_number),
        orderDate: order.order_date,
        total: Number(order.total ?? 0),
        paymentTerms: order.payment_terms,
      },
      items: items.map((row) => ({
        productId: row.product_id,
        productName: row.product_name,
        productVariantId: row.product_variant_id,
        variantName: row.variant_name,
        quantity: Number(row.quantity ?? 0),
        previousPrice: Number(row.unit_price ?? 0),
        currentPrice: Number(row.current_price ?? 0),
        priceChanged: Number(row.unit_price ?? 0) !== Number(row.current_price ?? 0),
        stockAvailable: Number(row.stock_available ?? 0),
        hasStock: Number(row.stock_available ?? 0) >= Number(row.quantity ?? 0),
        hasVariants: row.has_variants === true,
      })),
    };
  }

  async deactivate(id) {
    const row = await clientRepository.deactivate(id);
    if (!row) {
      throw new AppError('Cliente no encontrado.', 404);
    }

    return formatClient(row);
  }

  async activate(id) {
    const row = await clientRepository.activate(id);
    if (!row) {
      throw new AppError('Cliente no encontrado.', 404);
    }

    return formatClient(row);
  }

  async remove(id) {
    const existing = await clientRepository.findById(id);
    if (!existing) {
      throw new AppError('Cliente no encontrado.', 404);
    }

    const hasMovements = await clientRepository.hasAssociatedMovements(id);
    if (hasMovements) {
      throw new AppError(
        'Este cliente tiene movimientos asociados y no se puede eliminar. Podés desactivarlo.',
        409,
        { canDeactivate: true },
      );
    }

    await clientRepository.remove(id);
    return { id };
  }
}

export const clientService = new ClientService();
