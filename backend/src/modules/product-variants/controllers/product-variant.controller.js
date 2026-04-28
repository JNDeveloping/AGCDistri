import { created, ok } from '../../../utils/api-response.js';
import { productVariantService } from '../services/product-variant.service.js';

export const listProductVariantsController = async (req, res) => ok(res, await productVariantService.listByProduct(req.params.id), 'Variantes obtenidas.');
export const createProductVariantController = async (req, res) => created(res, await productVariantService.create(req.params.id, req.body), 'Variante creada.');
export const updateProductVariantController = async (req, res) => ok(res, await productVariantService.update(req.params.id, req.body), 'Variante actualizada.');
export const deactivateProductVariantController = async (req, res) => ok(res, await productVariantService.deactivate(req.params.id), 'Variante desactivada.');
export const activateProductVariantController = async (req, res) => ok(res, await productVariantService.activate(req.params.id), 'Variante activada.');
export const deleteProductVariantController = async (req, res) => ok(res, await productVariantService.remove(req.params.id), 'Variante eliminada.');

