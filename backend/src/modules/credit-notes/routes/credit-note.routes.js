import { Router } from 'express';

import { USER_ROLES } from '../../../config/constants.js';
import { authenticate } from '../../../middlewares/authenticate.js';
import { asyncHandler } from '../../../middlewares/async-handler.js';
import { authorize } from '../../../middlewares/authorize.js';
import { validate } from '../../../middlewares/validate.js';
import {
  createCreditNoteController,
  getCreditNoteByIdController,
  listCreditNotesController,
  listOrderCreditNotesController,
} from '../controllers/credit-note.controller.js';
import { createCreditNoteSchema, listCreditNotesQuerySchema } from '../validators/credit-note.validator.js';

const creditNoteRouter = Router();
creditNoteRouter.use(authenticate);

creditNoteRouter.post('/credit-notes', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR), validate(createCreditNoteSchema), asyncHandler(createCreditNoteController));
creditNoteRouter.get('/credit-notes', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR, USER_ROLES.REPARTIDOR), validate(listCreditNotesQuerySchema, 'query'), asyncHandler(listCreditNotesController));
creditNoteRouter.get('/credit-notes/:id', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR, USER_ROLES.REPARTIDOR), asyncHandler(getCreditNoteByIdController));
creditNoteRouter.get('/orders/:id/credit-notes', authorize(USER_ROLES.ADMIN, USER_ROLES.VENDEDOR, USER_ROLES.REPARTIDOR), asyncHandler(listOrderCreditNotesController));

export { creditNoteRouter };

