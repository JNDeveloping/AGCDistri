import { AppError } from '../../../errors/app-error.js';
import { productCategoryRepository } from '../repositories/product-category.repository.js';

const mapCategory = (row) => ({
  id: row.id,
  name: row.name,
  description: row.description,
  isActive: row.is_active,
  createdAt: row.created_at,
  updatedAt: row.updated_at,
  deactivatedAt: row.deactivated_at,
});

export class ProductCategoryService {
  async list(includeInactive) {
    const rows = await productCategoryRepository.list(includeInactive);
    return rows.map(mapCategory);
  }

  async create(payload) {
    const duplicated = await productCategoryRepository.findByName(payload.name);
    if (duplicated) {
      throw new AppError('Ya existe una categoría con ese nombre.', 409);
    }

    const created = await productCategoryRepository.create(payload);
    return mapCategory(created);
  }

  async update(id, payload) {
    const existing = await productCategoryRepository.findById(id);
    if (!existing) {
      throw new AppError('Categoría no encontrada.', 404);
    }

    if (payload.name) {
      const duplicated = await productCategoryRepository.findByName(payload.name, id);
      if (duplicated) {
        throw new AppError('Ya existe una categoría con ese nombre.', 409);
      }
    }

    const updated = await productCategoryRepository.update(id, payload);
    return mapCategory(updated);
  }

  async deactivate(id) {
    const existing = await productCategoryRepository.findById(id);
    if (!existing) {
      throw new AppError('Categoría no encontrada.', 404);
    }

    const updated = await productCategoryRepository.deactivate(id);
    return mapCategory(updated);
  }
}

export const productCategoryService = new ProductCategoryService();
