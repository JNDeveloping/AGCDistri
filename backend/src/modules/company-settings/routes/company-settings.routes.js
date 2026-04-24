import { Router } from 'express';

import { USER_ROLES } from '../../../config/constants.js';
import { authenticate } from '../../../middlewares/authenticate.js';
import { asyncHandler } from '../../../middlewares/async-handler.js';
import { authorize } from '../../../middlewares/authorize.js';
import { validate } from '../../../middlewares/validate.js';
import {
  getCompanySettingsController,
  resetCompanySettingsController,
  upsertCompanySettingsController,
} from '../controllers/company-settings.controller.js';
import { upsertCompanySettingsSchema } from '../validators/company-settings.validator.js';

const companySettingsRouter = Router();

companySettingsRouter.use(authenticate);
companySettingsRouter.get('/', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR, USER_ROLES.REPARTIDOR), asyncHandler(getCompanySettingsController));
companySettingsRouter.use(authorize(USER_ROLES.ADMIN));
companySettingsRouter.put('/', validate(upsertCompanySettingsSchema), asyncHandler(upsertCompanySettingsController));
companySettingsRouter.post('/reset', asyncHandler(resetCompanySettingsController));

export { companySettingsRouter };
