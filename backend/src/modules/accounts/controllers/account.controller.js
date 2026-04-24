import { created, ok } from '../../../utils/api-response.js';
import { accountService } from '../services/account.service.js';

export const getClientAccountController = async (req, res) => ok(res, await accountService.getClientAccount(req.params.id), 'Cuenta corriente obtenida.');
export const listClientAccountMovementsController = async (req, res) => ok(res, await accountService.listClientMovements(req.params.id, req.query), 'Movimientos obtenidos.');
export const createClientAccountMovementController = async (req, res) => created(res, await accountService.createMovement(req.params.id, req.body, req.user), 'Movimiento registrado.');
export const adjustClientAccountController = async (req, res) => created(res, await accountService.adjustBalance(req.params.id, req.body, req.user), 'Ajuste registrado.');
export const listDebtorsController = async (_req, res) => ok(res, await accountService.debtors(), 'Deudores obtenidos.');
export const getAccountsSummaryController = async (_req, res) => ok(res, await accountService.summary(), 'Resumen obtenido.');
export const createClientPaymentController = async (req, res) => created(res, await accountService.registerPayment(req.body, req.user), 'Pago registrado.');
export const listClientPaymentsController = async (req, res) => ok(res, await accountService.listPayments(req.query), 'Pagos obtenidos.');
export const getClientPaymentByIdController = async (req, res) => ok(res, await accountService.getPaymentById(req.params.id), 'Pago obtenido.');
