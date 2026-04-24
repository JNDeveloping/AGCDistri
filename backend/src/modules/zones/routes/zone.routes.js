import { Router } from 'express';

import { USER_ROLES } from '../../../config/constants.js';
import { authenticate } from '../../../middlewares/authenticate.js';
import { asyncHandler } from '../../../middlewares/async-handler.js';
import { authorize } from '../../../middlewares/authorize.js';
import { validate } from '../../../middlewares/validate.js';
import {
  createZoneController,
  deactivateZoneController,
  listZonesController,
  updateZoneController,
} from '../controllers/zone.controller.js';
import { createZoneSchema, updateZoneSchema } from '../validators/zone.validator.js';

const zoneRouter = Router();

zoneRouter.use(authenticate);
zoneRouter.get('/', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR, USER_ROLES.REPARTIDOR), asyncHandler(listZonesController));
zoneRouter.post('/', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR), validate(createZoneSchema), asyncHandler(createZoneController));
zoneRouter.put('/:id', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR), validate(updateZoneSchema), asyncHandler(updateZoneController));
zoneRouter.patch('/:id/deactivate', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR), asyncHandler(deactivateZoneController));

export { zoneRouter };
