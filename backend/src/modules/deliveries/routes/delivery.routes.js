import { Router } from 'express';

import { USER_ROLES } from '../../../config/constants.js';
import { authenticate } from '../../../middlewares/authenticate.js';
import { asyncHandler } from '../../../middlewares/async-handler.js';
import { authorize } from '../../../middlewares/authorize.js';
import { validate } from '../../../middlewares/validate.js';
import {
  addOrdersToDeliveryController,
  assignDeliveryDriverController,
  changeDeliveryStatusController,
  createDeliveryController,
  getDeliveryByIdController,
  listDeliveriesController,
  listPendingDeliveryOrdersController,
  optimizeDeliveryRouteController,
  todayRoutesController,
  updateDeliveryOrderStatusController,
} from '../controllers/delivery.controller.js';
import {
  addOrdersToDeliverySchema,
  assignDriverSchema,
  changeDeliveryStatusSchema,
  createDeliverySchema,
  listDeliveriesQuerySchema,
  optimizeRouteSchema,
  pendingDeliveryOrdersQuerySchema,
  updateDeliveryOrderStatusSchema,
} from '../validators/delivery.validator.js';

const deliveryRouter = Router();
deliveryRouter.use(authenticate);

deliveryRouter.get('/deliveries', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR, USER_ROLES.REPARTIDOR), validate(listDeliveriesQuerySchema, 'query'), asyncHandler(listDeliveriesController));
deliveryRouter.post('/deliveries', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR), validate(createDeliverySchema), asyncHandler(createDeliveryController));
deliveryRouter.get('/deliveries/:id', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR, USER_ROLES.REPARTIDOR), asyncHandler(getDeliveryByIdController));
deliveryRouter.patch('/deliveries/:id/status', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR), validate(changeDeliveryStatusSchema), asyncHandler(changeDeliveryStatusController));
deliveryRouter.patch('/deliveries/:id/assign-driver', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR), validate(assignDriverSchema), asyncHandler(assignDeliveryDriverController));
deliveryRouter.post('/deliveries/:id/orders', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR), validate(addOrdersToDeliverySchema), asyncHandler(addOrdersToDeliveryController));
deliveryRouter.get('/orders/pending-delivery', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR), validate(pendingDeliveryOrdersQuerySchema, 'query'), asyncHandler(listPendingDeliveryOrdersController));
deliveryRouter.get('/routes/today', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR, USER_ROLES.REPARTIDOR), asyncHandler(todayRoutesController));
deliveryRouter.patch('/deliveries/orders/:deliveryOrderId/status', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR, USER_ROLES.REPARTIDOR), validate(updateDeliveryOrderStatusSchema), asyncHandler(updateDeliveryOrderStatusController));
deliveryRouter.post('/deliveries/:id/optimize-route', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR, USER_ROLES.REPARTIDOR), validate(optimizeRouteSchema), asyncHandler(optimizeDeliveryRouteController));

export { deliveryRouter };
