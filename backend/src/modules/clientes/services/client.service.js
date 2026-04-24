import { AppError } from '../../../errors/app-error.js';
import { clientRepository } from '../repositories/client.repository.js';

const formatClient = (row) => {
  if (!row) {
    return null;
  }

  return {
    id: row.id,
    internalCode: row.internal_code,
    businessName: row.business_name,
    contactName: row.contact_name,
    phone: row.phone,
    alternatePhone: row.alternate_phone,
    email: row.email,
    taxId: row.tax_id,
    addressLine: row.address_line,
    city: row.city,
    province: row.province,
    routeZone: row.route_zone,
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
  contactName: client.contactName,
  phone: client.phone,
  addressLine: client.addressLine,
  city: client.city,
  province: client.province,
  routeZone: client.routeZone,
  latitude: client.latitude,
  longitude: client.longitude,
  isActive: client.isActive,
});

export class ClientService {
  async create(payload) {
    const duplicated = await clientRepository.findByCodeOrTaxId({
      internalCode: payload.internalCode,
      taxId: payload.taxId ?? null,
    });

    if (duplicated) {
      throw new AppError('Ya existe un cliente con ese código interno o CUIT.', 409);
    }

    const created = await clientRepository.create(payload);
    return formatClient(created);
  }

  async list({ q, isActive, page, limit, role }) {
    const result = await clientRepository.list({ q, isActive, page, limit });
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

    const updated = await clientRepository.update(id, payload);
    return formatClient(updated);
  }

  async deactivate(id) {
    const row = await clientRepository.deactivate(id);
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
        'No se puede eliminar este cliente porque tiene movimientos asociados. Podés desactivarlo.',
        409,
      );
    }

    await clientRepository.remove(id);
    return { id };
  }
}

export const clientService = new ClientService();
