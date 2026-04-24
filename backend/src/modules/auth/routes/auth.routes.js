import { Router } from 'express';

import { authenticate } from '../../../middlewares/authenticate.js';
import { asyncHandler } from '../../../middlewares/async-handler.js';
import { validate } from '../../../middlewares/validate.js';
import { loginController, meController, registerController } from '../controllers/auth.controller.js';
import { loginSchema, registerSchema } from '../validators/auth.validator.js';

const authRouter = Router();

authRouter.post('/register', validate(registerSchema), asyncHandler(registerController));
authRouter.post('/login', validate(loginSchema), asyncHandler(loginController));
authRouter.get('/me', authenticate, asyncHandler(meController));

export { authRouter };
