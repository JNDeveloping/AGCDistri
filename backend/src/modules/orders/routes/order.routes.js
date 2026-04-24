import { Router } from 'express';

import { USER_ROLES } from '../../../config/constants.js';
import { authenticate } from '../../../middlewares/authenticate.js';
import { asyncHandler } from '../../../middlewares/async-handler.js';
import { authorize } from '../../../middlewares/authorize.js';
import { validate } from '../../../middlewares/validate.js';
import {
  cancelOrderController,
  changeOrderStatusController,
  createOrderController,
  deleteOrderController,
  getOrderController,
  listOrdersController,
  updateOrderController,
} from '../controllers/order.controller.js';
import {
  changeOrderStatusSchema,
  createOrderSchema,
  listOrdersQuerySchema,
  updateOrderSchema,
} from '../validators/order.validator.js';

const orderRouter = Router();
orderRouter.use(authenticate);

orderRouter.get('/', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR, USER_ROLES.REPARTIDOR), validate(listOrdersQuerySchema, 'query'), asyncHandler(listOrdersController));
orderRouter.get('/:id', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR, USER_ROLES.REPARTIDOR), asyncHandler(getOrderController));
orderRouter.post('/', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR), validate(createOrderSchema), asyncHandler(createOrderController));
orderRouter.put('/:id', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR), validate(updateOrderSchema), asyncHandler(updateOrderController));
orderRouter.patch('/:id/cancel', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR), asyncHandler(cancelOrderController));
orderRouter.patch('/:id/status', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR, USER_ROLES.REPARTIDOR), validate(changeOrderStatusSchema), asyncHandler(changeOrderStatusController));
orderRouter.delete('/:id', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR), asyncHandler(deleteOrderController));

export { orderRouter };
