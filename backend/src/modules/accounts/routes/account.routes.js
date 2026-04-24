import { Router } from 'express';

import { USER_ROLES } from '../../../config/constants.js';
import { authenticate } from '../../../middlewares/authenticate.js';
import { asyncHandler } from '../../../middlewares/async-handler.js';
import { authorize } from '../../../middlewares/authorize.js';
import { validate } from '../../../middlewares/validate.js';
import {
  adjustClientAccountController,
  createClientAccountMovementController,
  createClientPaymentController,
  getAccountsSummaryController,
  getClientAccountController,
  getClientPaymentByIdController,
  listClientAccountMovementsController,
  listClientPaymentsController,
  listDebtorsController,
} from '../controllers/account.controller.js';
import {
  adjustAccountSchema,
  createAccountMovementSchema,
  createClientPaymentSchema,
  listAccountMovementsQuerySchema,
  listPaymentsQuerySchema,
} from '../validators/account.validator.js';

const accountRouter = Router();
const paymentRouter = Router();

accountRouter.use(authenticate);
paymentRouter.use(authenticate);

accountRouter.get('/clients/:id/account', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR, USER_ROLES.REPARTIDOR), asyncHandler(getClientAccountController));
accountRouter.get('/clients/:id/account-movements', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR, USER_ROLES.REPARTIDOR), validate(listAccountMovementsQuerySchema, 'query'), asyncHandler(listClientAccountMovementsController));
accountRouter.post('/clients/:id/account-movements', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR), validate(createAccountMovementSchema), asyncHandler(createClientAccountMovementController));
accountRouter.post('/clients/:id/account-adjustment', authorize(USER_ROLES.ADMIN), validate(adjustAccountSchema), asyncHandler(adjustClientAccountController));
accountRouter.get('/accounts/debtors', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR), asyncHandler(listDebtorsController));
accountRouter.get('/accounts/summary', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR), asyncHandler(getAccountsSummaryController));

paymentRouter.post('/client-payments', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR, USER_ROLES.REPARTIDOR), validate(createClientPaymentSchema), asyncHandler(createClientPaymentController));
paymentRouter.get('/client-payments', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR, USER_ROLES.REPARTIDOR), validate(listPaymentsQuerySchema, 'query'), asyncHandler(listClientPaymentsController));
paymentRouter.get('/client-payments/:id', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR, USER_ROLES.REPARTIDOR), asyncHandler(getClientPaymentByIdController));

export { accountRouter, paymentRouter };
