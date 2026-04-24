import { created, ok } from '../../../utils/api-response.js';
import { productCategoryService } from '../services/product-category.service.js';

export const listProductCategoriesController = async (req, res) => {
  const includeInactive = req.query.includeInactive === 'true';
  const data = await productCategoryService.list(includeInactive);
  return ok(res, data, 'Categorías obtenidas correctamente.');
};

export const createProductCategoryController = async (req, res) => {
  const data = await productCategoryService.create(req.body);
  return created(res, data, 'Categoría creada correctamente.');
};

export const updateProductCategoryController = async (req, res) => {
  const data = await productCategoryService.update(req.params.id, req.body);
  return ok(res, data, 'Categoría actualizada correctamente.');
};

export const deactivateProductCategoryController = async (req, res) => {
  const data = await productCategoryService.deactivate(req.params.id);
  return ok(res, data, 'Categoría desactivada correctamente.');
};
