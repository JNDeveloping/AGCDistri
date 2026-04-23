import { Router } from 'express';

import { authenticate } from '../../../middlewares/authenticate.js';
import { validate } from '../../../middlewares/validate.js';
import { loginController, meController } from '../controllers/auth.controller.js';
import { loginSchema } from '../validators/auth.validator.js';

const authRouter = Router();

authRouter.post('/login', validate(loginSchema), loginController);
authRouter.get('/me', authenticate, meController);

export { authRouter };
