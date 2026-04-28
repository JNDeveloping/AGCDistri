import { created, ok } from '../../../utils/api-response.js';
import { creditNoteService } from '../services/credit-note.service.js';

export const createCreditNoteController = async (req, res) => created(res, await creditNoteService.create(req.body, req.user), 'Nota de crédito creada.');
export const listCreditNotesController = async (req, res) => ok(res, await creditNoteService.list(req.query), 'Notas de crédito obtenidas.');
export const getCreditNoteByIdController = async (req, res) => ok(res, await creditNoteService.getById(req.params.id), 'Nota de crédito obtenida.');
export const listOrderCreditNotesController = async (req, res) => ok(res, await creditNoteService.listByOrder(req.params.id), 'Notas de crédito del pedido obtenidas.');

