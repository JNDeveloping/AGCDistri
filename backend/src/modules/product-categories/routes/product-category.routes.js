import { Router } from 'express';

import { USER_ROLES } from '../../../config/constants.js';
import { authenticate } from '../../../middlewares/authenticate.js';
import { asyncHandler } from '../../../middlewares/async-handler.js';
import { authorize } from '../../../middlewares/authorize.js';
import { validate } from '../../../middlewares/validate.js';
import {
  activateProductCategoryController,
  createProductCategoryController,
  deactivateProductCategoryController,
  deleteProductCategoryController,
  listProductCategoriesController,
  moveCategoryProductsController,
  updateProductCategoryController,
} from '../controllers/product-category.controller.js';
import {
  createProductCategorySchema,
  listCategoryQuerySchema,
  moveCategoryProductsSchema,
  updateProductCategorySchema,
} from '../validators/product-category.validator.js';

const productCategoryRouter = Router();

productCategoryRouter.use(authenticate);
productCategoryRouter.get('/', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR), validate(listCategoryQuerySchema, 'query'), asyncHandler(listProductCategoriesController));
productCategoryRouter.post('/', authorize(USER_ROLES.ADMIN), validate(createProductCategorySchema), asyncHandler(createProductCategoryController));
productCategoryRouter.put('/:id', authorize(USER_ROLES.ADMIN), validate(updateProductCategorySchema), asyncHandler(updateProductCategoryController));
productCategoryRouter.patch('/:id/deactivate', authorize(USER_ROLES.ADMIN), asyncHandler(deactivateProductCategoryController));
productCategoryRouter.patch('/:id/activate', authorize(USER_ROLES.ADMIN), asyncHandler(activateProductCategoryController));
productCategoryRouter.patch('/:id/move-products', authorize(USER_ROLES.ADMIN), validate(moveCategoryProductsSchema), asyncHandler(moveCategoryProductsController));
productCategoryRouter.delete('/:id', authorize(USER_ROLES.ADMIN), asyncHandler(deleteProductCategoryController));

export { productCategoryRouter };
