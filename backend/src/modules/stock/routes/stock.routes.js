import { Router } from 'express';

import { USER_ROLES } from '../../../config/constants.js';
import { authenticate } from '../../../middlewares/authenticate.js';
import { asyncHandler } from '../../../middlewares/async-handler.js';
import { authorize } from '../../../middlewares/authorize.js';
import { validate } from '../../../middlewares/validate.js';
import {
  adjustStockController,
  createStockMovementController,
  getProductStockController,
  listProductStockMovementsController,
  listStockController,
  listStockMovementsController,
} from '../controllers/stock.controller.js';
import { adjustStockSchema, createStockMovementSchema, listStockMovementsQuerySchema } from '../validators/stock.validator.js';

const stockRouter = Router();
const stockMovementRouter = Router();

stockRouter.use(authenticate);
stockMovementRouter.use(authenticate);

stockRouter.get('/', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR, USER_ROLES.REPARTIDOR), asyncHandler(listStockController));
stockRouter.get('/products/:productId', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR, USER_ROLES.REPARTIDOR), asyncHandler(getProductStockController));
stockRouter.get('/products/:productId/movements', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR, USER_ROLES.REPARTIDOR), asyncHandler(listProductStockMovementsController));
stockRouter.post('/adjust', authorize(USER_ROLES.ADMIN), validate(adjustStockSchema), asyncHandler(adjustStockController));

stockMovementRouter.get('/', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR, USER_ROLES.REPARTIDOR), validate(listStockMovementsQuerySchema, 'query'), asyncHandler(listStockMovementsController));
stockMovementRouter.post('/', authorize(USER_ROLES.ADMIN), validate(createStockMovementSchema), asyncHandler(createStockMovementController));

export { stockMovementRouter, stockRouter };
