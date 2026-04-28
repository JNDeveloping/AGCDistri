import { Router } from 'express';

import { USER_ROLES } from '../../../config/constants.js';
import { authenticate } from '../../../middlewares/authenticate.js';
import { asyncHandler } from '../../../middlewares/async-handler.js';
import { authorize } from '../../../middlewares/authorize.js';
import { validate } from '../../../middlewares/validate.js';
import {
  getReportsDebtorsController,
  getReportsPaymentsController,
  getReportsProfitController,
  getReportsSalesController,
  getReportsStockController,
  getReportsSummaryController,
  getReportsTopClientsController,
  getReportsTopProductsController,
} from '../controllers/report.controller.js';
import { reportQuerySchema } from '../validators/report.validator.js';

const reportRouter = Router();
reportRouter.use(authenticate);
reportRouter.use(authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR));

reportRouter.get('/summary', validate(reportQuerySchema, 'query'), asyncHandler(getReportsSummaryController));
reportRouter.get('/sales', validate(reportQuerySchema, 'query'), asyncHandler(getReportsSalesController));
reportRouter.get('/profit', validate(reportQuerySchema, 'query'), asyncHandler(getReportsProfitController));
reportRouter.get('/top-clients', validate(reportQuerySchema, 'query'), asyncHandler(getReportsTopClientsController));
reportRouter.get('/top-products', validate(reportQuerySchema, 'query'), asyncHandler(getReportsTopProductsController));
reportRouter.get('/debtors', validate(reportQuerySchema, 'query'), asyncHandler(getReportsDebtorsController));
reportRouter.get('/stock', validate(reportQuerySchema, 'query'), asyncHandler(getReportsStockController));
reportRouter.get('/payments', validate(reportQuerySchema, 'query'), asyncHandler(getReportsPaymentsController));

export { reportRouter };
