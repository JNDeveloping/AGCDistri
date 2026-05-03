import { ok } from '../../../utils/api-response.js';
import { promotionService } from '../services/promotion.service.js';

export const listPromotionsController = async (req,res)=> ok(res, await promotionService.list(req.query), 'Promociones obtenidas.');
export const getPromotionController = async (req,res)=> ok(res, await promotionService.getById(req.params.id), 'Promoción obtenida.');
export const createPromotionController = async (req,res)=> res.status(201).json({ message:'Promoción creada.', data: await promotionService.create(req.body)});
export const updatePromotionController = async (req,res)=> ok(res, await promotionService.update(req.params.id, req.body), 'Promoción actualizada.');
export const deletePromotionController = async (req,res)=> ok(res, await promotionService.remove(req.params.id), 'Promoción archivada.');
export const togglePromotionController = async (req,res)=> ok(res, await promotionService.toggle(req.params.id), 'Promoción actualizada.');
export const previewPromotionController = async (req,res)=> ok(res, await promotionService.preview(req.body), 'Preview de promociones calculado.');
export const selectorsProductsController = async (req,res)=> ok(res, await promotionService.selectorsProducts(req.query.q, Number(req.query.limit ?? 25)), 'Selector de productos obtenido.');
export const selectorsCategoriesController = async (req,res)=> ok(res, await promotionService.selectorsCategories(), 'Selector de categorías obtenido.');
export const selectorsClientsController = async (req,res)=> ok(res, await promotionService.selectorsClients(req.query.q, Number(req.query.limit ?? 25)), 'Selector de clientes obtenido.');
export const selectorsZonesController = async (req,res)=> ok(res, await promotionService.selectorsZones(req.query.q, Number(req.query.limit ?? 25)), 'Selector de zonas obtenido.');
