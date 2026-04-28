import { Router } from 'express';

import { USER_ROLES } from '../../../config/constants.js';
import { authenticate } from '../../../middlewares/authenticate.js';
import { asyncHandler } from '../../../middlewares/async-handler.js';
import { authorize } from '../../../middlewares/authorize.js';
import { validate } from '../../../middlewares/validate.js';
import {
  activateProductVariantController,
  createProductVariantController,
  deactivateProductVariantController,
  deleteProductVariantController,
  listProductVariantsController,
  updateProductVariantController,
} from '../controllers/product-variant.controller.js';
import { createProductVariantSchema, updateProductVariantSchema } from '../validators/product-variant.validator.js';

const productVariantRouter = Router();

productVariantRouter.use(authenticate);
productVariantRouter.get('/products/:id/variants', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR, USER_ROLES.REPARTIDOR), asyncHandler(listProductVariantsController));
productVariantRouter.post('/products/:id/variants', authorize(USER_ROLES.ADMIN), validate(createProductVariantSchema), asyncHandler(createProductVariantController));
productVariantRouter.put('/product-variants/:id', authorize(USER_ROLES.ADMIN), validate(updateProductVariantSchema), asyncHandler(updateProductVariantController));
productVariantRouter.patch('/product-variants/:id/deactivate', authorize(USER_ROLES.ADMIN), asyncHandler(deactivateProductVariantController));
productVariantRouter.patch('/product-variants/:id/activate', authorize(USER_ROLES.ADMIN), asyncHandler(activateProductVariantController));
productVariantRouter.delete('/product-variants/:id', authorize(USER_ROLES.ADMIN), asyncHandler(deleteProductVariantController));

export { productVariantRouter };

