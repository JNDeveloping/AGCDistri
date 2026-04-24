import { Router } from 'express';

import { USER_ROLES } from '../../../config/constants.js';
import { authenticate } from '../../../middlewares/authenticate.js';
import { asyncHandler } from '../../../middlewares/async-handler.js';
import { authorize } from '../../../middlewares/authorize.js';
import { validate } from '../../../middlewares/validate.js';
import {
  createClientController,
  deleteClientController,
  deactivateClientController,
  getClientController,
  listClientsController,
  updateClientController,
} from '../controllers/client.controller.js';
import { createClientSchema, listClientQuerySchema, updateClientSchema } from '../validators/client.validator.js';

const clientRouter = Router();

clientRouter.use(authenticate);

clientRouter.get(
  '/',
  authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR, USER_ROLES.REPARTIDOR),
  validate(listClientQuerySchema, 'query'),
  asyncHandler(listClientsController),
);

clientRouter.get(
  '/:id',
  authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR, USER_ROLES.REPARTIDOR),
  asyncHandler(getClientController),
);

clientRouter.post('/', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR), validate(createClientSchema), asyncHandler(createClientController));
clientRouter.put('/:id', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR), validate(updateClientSchema), asyncHandler(updateClientController));
clientRouter.patch('/:id/deactivate', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR), asyncHandler(deactivateClientController));
clientRouter.delete('/:id', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR), asyncHandler(deleteClientController));

export { clientRouter };
