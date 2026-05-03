import { Router } from 'express';
import { USER_ROLES } from '../../../config/constants.js';
import { authenticate } from '../../../middlewares/authenticate.js';
import { authorize } from '../../../middlewares/authorize.js';
import { asyncHandler } from '../../../middlewares/async-handler.js';
import { validate } from '../../../middlewares/validate.js';
import { createPromotionController, deletePromotionController, getPromotionController, listPromotionsController, previewPromotionController, selectorsCategoriesController, selectorsClientsController, selectorsProductsController, selectorsZonesController, togglePromotionController, updatePromotionController } from '../controllers/promotion.controller.js';
import { listPromotionsQuerySchema, previewPromotionSchema, upsertPromotionSchema } from '../validators/promotion.validator.js';

const promotionRouter = Router();
promotionRouter.use(authenticate);
promotionRouter.get('/', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR), validate(listPromotionsQuerySchema, 'query'), asyncHandler(listPromotionsController));
promotionRouter.get('/selectors/products', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR), asyncHandler(selectorsProductsController));
promotionRouter.get('/selectors/categories', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR), asyncHandler(selectorsCategoriesController));
promotionRouter.get('/selectors/clients', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR), asyncHandler(selectorsClientsController));
promotionRouter.get('/selectors/zones', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR), asyncHandler(selectorsZonesController));
promotionRouter.get('/:id', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR), asyncHandler(getPromotionController));
promotionRouter.post('/', authorize(USER_ROLES.ADMIN), validate(upsertPromotionSchema), asyncHandler(createPromotionController));
promotionRouter.put('/:id', authorize(USER_ROLES.ADMIN), validate(upsertPromotionSchema), asyncHandler(updatePromotionController));
promotionRouter.delete('/:id', authorize(USER_ROLES.ADMIN), asyncHandler(deletePromotionController));
promotionRouter.post('/:id/toggle', authorize(USER_ROLES.ADMIN), asyncHandler(togglePromotionController));
promotionRouter.post('/preview', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR), validate(previewPromotionSchema), asyncHandler(previewPromotionController));

export { promotionRouter };
