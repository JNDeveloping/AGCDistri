import { created, ok } from '../../../utils/api-response.js';
import { productService } from '../services/product.service.js';

export const listProductsController = async (req, res) => {
  const payload = await productService.list({
    q: req.query.q,
    isActive: req.query.isActive === undefined ? undefined : req.query.isActive === 'true',
    lowStock: req.query.lowStock === 'true',
    page: Number(req.query.page ?? 1),
    limit: Number(req.query.limit ?? 20),
    role: req.user.role,
  });

  return ok(res, payload, 'Productos obtenidos correctamente.');
};

export const getProductController = async (req, res) => {
  const payload = await productService.getById(req.params.id, req.user.role);
  return ok(res, payload, 'Detalle de producto obtenido correctamente.');
};

export const createProductController = async (req, res) => {
  const payload = await productService.create(req.body);
  return created(res, payload, 'Producto creado correctamente.');
};

export const updateProductController = async (req, res) => {
  const payload = await productService.update(req.params.id, req.body);
  return ok(res, payload, 'Producto actualizado correctamente.');
};

export const deactivateProductController = async (req, res) => {
  const payload = await productService.deactivate(req.params.id);
  return ok(res, payload, 'Producto desactivado correctamente.');
};
