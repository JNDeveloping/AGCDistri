import { created, ok } from '../../../utils/api-response.js';
import { stockService } from '../services/stock.service.js';

export const listStockController = async (req, res) => {
  const data = await stockService.listStock({
    q: req.query.q,
    lowStock: req.query.lowStock === 'true',
    outOfStock: req.query.outOfStock === 'true',
  });
  return ok(res, data, 'Stock obtenido correctamente.');
};

export const getProductStockController = async (req, res) => {
  const data = await stockService.getProductStock(req.params.productId);
  return ok(res, data, 'Stock del producto obtenido correctamente.');
};

export const listStockMovementsController = async (req, res) => {
  const data = await stockService.listMovements(req.query);
  return ok(res, data, 'Movimientos de stock obtenidos correctamente.');
};

export const createStockMovementController = async (req, res) => {
  const data = await stockService.createMovement(req.body, req.user);
  return created(res, data, 'Movimiento de stock registrado correctamente.');
};

export const adjustStockController = async (req, res) => {
  const data = await stockService.adjust(req.body, req.user);
  return created(res, data, 'Ajuste de stock aplicado correctamente.');
};

export const listProductStockMovementsController = async (req, res) => {
  const data = await stockService.listMovements({ ...req.query, productId: req.params.productId });
  return ok(res, data, 'Historial del producto obtenido correctamente.');
};
