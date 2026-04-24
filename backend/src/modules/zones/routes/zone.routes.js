import { Router } from 'express';

import { USER_ROLES } from '../../../config/constants.js';
import { authenticate } from '../../../middlewares/authenticate.js';
import { asyncHandler } from '../../../middlewares/async-handler.js';
import { authorize } from '../../../middlewares/authorize.js';
import { validate } from '../../../middlewares/validate.js';
import {
  activateZoneController,
  createZoneController,
  deactivateZoneController,
  deleteZoneController,
  listZonesController,
  moveZoneClientsController,
  updateZoneController,
} from '../controllers/zone.controller.js';
import { createZoneSchema, moveZoneClientsSchema, updateZoneSchema } from '../validators/zone.validator.js';

const zoneRouter = Router();

zoneRouter.use(authenticate);
zoneRouter.get('/', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR), asyncHandler(listZonesController));
zoneRouter.post('/', authorize(USER_ROLES.ADMIN), validate(createZoneSchema), asyncHandler(createZoneController));
zoneRouter.put('/:id', authorize(USER_ROLES.ADMIN), validate(updateZoneSchema), asyncHandler(updateZoneController));
zoneRouter.patch('/:id/deactivate', authorize(USER_ROLES.ADMIN), asyncHandler(deactivateZoneController));
zoneRouter.patch('/:id/activate', authorize(USER_ROLES.ADMIN), asyncHandler(activateZoneController));
zoneRouter.patch('/:id/move-clients', authorize(USER_ROLES.ADMIN), validate(moveZoneClientsSchema), asyncHandler(moveZoneClientsController));
zoneRouter.delete('/:id', authorize(USER_ROLES.ADMIN), asyncHandler(deleteZoneController));

export { zoneRouter };
