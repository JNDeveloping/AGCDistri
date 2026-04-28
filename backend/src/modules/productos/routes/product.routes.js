import { Router } from 'express';

import { USER_ROLES } from '../../../config/constants.js';
import { authenticate } from '../../../middlewares/authenticate.js';
import { asyncHandler } from '../../../middlewares/async-handler.js';
import { authorize } from '../../../middlewares/authorize.js';
import { validate } from '../../../middlewares/validate.js';
import {
  autocompleteProductsController,
  createProductController,
  deactivateProductController,
  getProductController,
  listProductsController,
  updateProductController,
} from '../controllers/product.controller.js';
import { createProductSchema, listProductQuerySchema, updateProductSchema } from '../validators/product.validator.js';

const productRouter = Router();

productRouter.use(authenticate);
productRouter.get('/autocomplete', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR, USER_ROLES.REPARTIDOR), asyncHandler(autocompleteProductsController));
productRouter.get('/', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR, USER_ROLES.REPARTIDOR), validate(listProductQuerySchema, 'query'), asyncHandler(listProductsController));
productRouter.get('/:id', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR, USER_ROLES.REPARTIDOR), asyncHandler(getProductController));
productRouter.post('/', authorize(USER_ROLES.ADMIN), validate(createProductSchema), asyncHandler(createProductController));
productRouter.put('/:id', authorize(USER_ROLES.ADMIN), validate(updateProductSchema), asyncHandler(updateProductController));
productRouter.patch('/:id/deactivate', authorize(USER_ROLES.ADMIN), asyncHandler(deactivateProductController));

export { productRouter };
