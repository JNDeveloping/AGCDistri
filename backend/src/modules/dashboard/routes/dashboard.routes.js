import { Router } from 'express';

import { USER_ROLES } from '../../../config/constants.js';
import { authenticate } from '../../../middlewares/authenticate.js';
import { asyncHandler } from '../../../middlewares/async-handler.js';
import { authorize } from '../../../middlewares/authorize.js';
import { getDashboardStatsController } from '../controllers/dashboard.controller.js';

const dashboardRouter = Router();

dashboardRouter.use(authenticate);
dashboardRouter.get('/', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR, USER_ROLES.REPARTIDOR), asyncHandler(getDashboardStatsController));
dashboardRouter.get('/stats', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR, USER_ROLES.REPARTIDOR), asyncHandler(getDashboardStatsController));

export { dashboardRouter };
