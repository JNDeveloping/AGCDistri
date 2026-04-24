import { AppError } from '../../../errors/app-error.js';
import { zoneRepository } from '../repositories/zone.repository.js';

const mapZone = (row) => ({
  id: row.id,
  name: row.name,
  description: row.description,
  isActive: row.is_active,
  createdAt: row.created_at,
  updatedAt: row.updated_at,
  deactivatedAt: row.deactivated_at,
});

export class ZoneService {
  async list(includeInactive) {
    const rows = await zoneRepository.list({ includeInactive });
    return rows.map(mapZone);
  }

  async create(payload) {
    const duplicated = await zoneRepository.findByName(payload.name);
    if (duplicated) throw new AppError('Ya existe una zona/ruta con ese nombre.', 409);
    return mapZone(await zoneRepository.create(payload));
  }

  async update(id, payload) {
    const existing = await zoneRepository.findById(id);
    if (!existing) throw new AppError('Zona/ruta no encontrada.', 404);
    if (payload.name) {
      const duplicated = await zoneRepository.findByName(payload.name, id);
      if (duplicated) throw new AppError('Ya existe una zona/ruta con ese nombre.', 409);
    }
    return mapZone(await zoneRepository.update(id, payload));
  }

  async deactivate(id) {
    const updated = await zoneRepository.deactivate(id);
    if (!updated) throw new AppError('Zona/ruta no encontrada.', 404);
    return mapZone(updated);
  }
}

export const zoneService = new ZoneService();
