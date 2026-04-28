import { Router } from 'express';

import { USER_ROLES } from '../../../config/constants.js';
import { authenticate } from '../../../middlewares/authenticate.js';
import { asyncHandler } from '../../../middlewares/async-handler.js';
import { authorize } from '../../../middlewares/authorize.js';
import { validate } from '../../../middlewares/validate.js';
import {
  activateUserController,
  createUserController,
  deactivateUserController,
  deleteUserController,
  listUsersController,
  updateUserController,
} from '../controllers/user.controller.js';
import { createUserSchema, updateUserSchema } from '../validators/user.validator.js';

const userRouter = Router();

userRouter.use(authenticate);
userRouter.use(authorize(USER_ROLES.ADMIN));

userRouter.get('/', asyncHandler(listUsersController));
userRouter.post('/', validate(createUserSchema), asyncHandler(createUserController));
userRouter.put('/:id', validate(updateUserSchema), asyncHandler(updateUserController));
userRouter.patch('/:id/deactivate', asyncHandler(deactivateUserController));
userRouter.patch('/:id/activate', asyncHandler(activateUserController));
userRouter.delete('/:id', asyncHandler(deleteUserController));

export { userRouter };
