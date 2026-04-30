import { Router } from 'express';
import { USER_ROLES } from '../../../config/constants.js';
import { authenticate } from '../../../middlewares/authenticate.js';
import { authorize } from '../../../middlewares/authorize.js';
import { asyncHandler } from '../../../middlewares/async-handler.js';
import { validate } from '../../../middlewares/validate.js';
import { createPromotionController, deletePromotionController, getPromotionController, listPromotionsController, togglePromotionController, updatePromotionController } from '../controllers/promotion.controller.js';
import { listPromotionsQuerySchema, upsertPromotionSchema } from '../validators/promotion.validator.js';

const promotionRouter = Router();
promotionRouter.use(authenticate);
promotionRouter.get('/', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR), validate(listPromotionsQuerySchema, 'query'), asyncHandler(listPromotionsController));
promotionRouter.get('/:id', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR), asyncHandler(getPromotionController));
promotionRouter.post('/', authorize(USER_ROLES.ADMIN), validate(upsertPromotionSchema), asyncHandler(createPromotionController));
promotionRouter.put('/:id', authorize(USER_ROLES.ADMIN), validate(upsertPromotionSchema), asyncHandler(updatePromotionController));
promotionRouter.delete('/:id', authorize(USER_ROLES.ADMIN), asyncHandler(deletePromotionController));
promotionRouter.post('/:id/toggle', authorize(USER_ROLES.ADMIN), asyncHandler(togglePromotionController));

export { promotionRouter };
