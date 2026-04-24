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

  async activate(id) {
    const updated = await zoneRepository.activate(id);
    if (!updated) throw new AppError('Zona/ruta no encontrada.', 404);
    return mapZone(updated);
  }

  async moveClients(id, destinationZoneId) {
    if (id === destinationZoneId) {
      throw new AppError('La zona destino debe ser distinta a la zona origen.', 400);
    }

    const [origin, destination] = await Promise.all([
      zoneRepository.findById(id),
      zoneRepository.findById(destinationZoneId),
    ]);

    if (!origin) throw new AppError('Zona/ruta origen no encontrada.', 404);
    if (!destination) throw new AppError('Zona/ruta destino no encontrada.', 404);

    const moved = await zoneRepository.moveClients({ fromZoneId: id, toZoneId: destinationZoneId });
    return { moved, fromZoneId: id, toZoneId: destinationZoneId };
  }

  async remove(id) {
    const existing = await zoneRepository.findById(id);
    if (!existing) throw new AppError('Zona/ruta no encontrada.', 404);

    const assignedClients = await zoneRepository.countAssignedClients(id);
    if (assignedClients > 0) {
      throw new AppError('Esta zona tiene clientes asociados. Mové los clientes a otra zona antes de eliminarla.', 409);
    }

    const deleted = await zoneRepository.remove(id);
    if (!deleted) throw new AppError('Zona/ruta no encontrada.', 404);

    return { id };
  }
}

export const zoneService = new ZoneService();
