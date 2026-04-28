import { AppError } from '../../../errors/app-error.js';
import { accountRepository } from '../repositories/account.repository.js';

const debitTypes = new Set(['deuda', 'ajuste']);

const mapMovement = (row) => ({
  id: row.id,
  clientId: row.client_id,
  clientName: row.client_name,
  movementType: row.movement_type,
  amount: Number(row.amount),
  previousBalance: Number(row.previous_balance),
  newBalance: Number(row.new_balance),
  description: row.description,
  notes: row.notes,
  userId: row.user_id,
  userName: row.user_name,
  referenceType: row.reference_type,
  referenceId: row.reference_id,
  createdAt: row.created_at,
});

const computeStatus = (balance) => {
  const value = Number(balance ?? 0);
  if (value > 0) return 'con_deuda';
  if (value < 0) return 'saldo_a_favor';
  return 'al_dia';
};

export class AccountService {
  async getClientAccount(clientId) {
    const client = await accountRepository.findClient(clientId);
    if (!client) throw new AppError('Cliente no encontrado.', 404);

    const movements = await accountRepository.listMovements({ clientId });
    return {
      clientId: client.id,
      businessName: client.business_name,
      currentBalance: Number(client.current_balance),
      creditLimit: Number(client.credit_limit),
      status: computeStatus(client.current_balance),
      lastMovementAt: movements[0]?.created_at ?? null,
      recentMovements: movements.slice(0, 10).map(mapMovement),
    };
  }

  async listClientMovements(clientId, filters) {
    await this.getClientAccount(clientId);
    const rows = await accountRepository.listMovements({ ...filters, clientId });
    return rows.map(mapMovement);
  }

  async createMovement(clientId, payload, user) {
    const client = await accountRepository.findClient(clientId);
    if (!client) throw new AppError('Cliente no encontrado.', 404);
    const amount = Number(payload.amount);
    if (!Number.isFinite(amount) || amount <= 0) throw new AppError('El monto debe ser mayor a cero.', 400);

    if (payload.movementType === 'ajuste' && user.role !== 'admin') {
      throw new AppError('Solo admin puede hacer ajustes manuales.', 403);
    }

    if (payload.referenceType && payload.referenceId) {
      const existing = await accountRepository.findMovementByReference({
        referenceType: payload.referenceType,
        referenceId: payload.referenceId,
        movementType: payload.movementType,
      });
      if (existing) {
        const row = await accountRepository.findMovementById(existing.id);
        return mapMovement({ ...row, client_name: client.business_name, user_name: user.fullName });
      }
    }

    const previous = Number(client.current_balance);
    const debit = debitTypes.has(payload.movementType);
    const next = debit ? previous + amount : previous - amount;

    await accountRepository.updateClientBalance(client.id, next);
    const saved = await accountRepository.createMovement({
      clientId: client.id,
      movementType: payload.movementType,
      amount,
      previousBalance: previous,
      newBalance: next,
      description: payload.description,
      notes: payload.notes,
      userId: user.sub,
      referenceType: payload.referenceType,
      referenceId: payload.referenceId,
    });
    return mapMovement({ ...saved, client_name: client.business_name, user_name: user.fullName });
  }

  async applyOrderDebt({ orderId, clientId, total, userId }) {
    const existing = await accountRepository.findMovementByReference({ referenceType: 'order', referenceId: orderId, movementType: 'deuda' });
    if (existing) return;
    const client = await accountRepository.findClient(clientId);
    if (!client) return;

    const previous = Number(client.current_balance);
    const next = previous + Number(total);
    await accountRepository.updateClientBalance(clientId, next);
    await accountRepository.createMovement({
      clientId,
      movementType: 'deuda',
      amount: Number(total),
      previousBalance: previous,
      newBalance: next,
      description: 'Deuda por pedido en cuenta corriente',
      notes: `Pedido ${orderId}`,
      userId,
      referenceType: 'order',
      referenceId: orderId,
    });
  }

  async reverseOrderDebt({ orderId, clientId, total, userId }) {
    const existing = await accountRepository.findMovementByReference({ referenceType: 'order', referenceId: orderId, movementType: 'deuda' });
    if (!existing) return;
    const alreadyReversed = await accountRepository.findMovementByReference({ referenceType: 'order', referenceId: orderId, movementType: 'anulacion' });
    if (alreadyReversed) return;

    const client = await accountRepository.findClient(clientId);
    if (!client) return;

    const previous = Number(client.current_balance);
    const next = previous - Number(total);
    await accountRepository.updateClientBalance(clientId, next);
    await accountRepository.createMovement({
      clientId,
      movementType: 'anulacion',
      amount: Number(total),
      previousBalance: previous,
      newBalance: next,
      description: 'Anulación de deuda por cancelación de pedido',
      notes: `Pedido ${orderId}`,
      userId,
      referenceType: 'order',
      referenceId: orderId,
    });
  }

  async adjustBalance(clientId, payload, user) {
    return this.createMovement(clientId, { ...payload, movementType: 'ajuste' }, user);
  }

  async debtors() {
    const rows = await accountRepository.listDebtors();
    return rows.map((r) => ({
      clientId: r.id,
      businessName: r.business_name,
      currentBalance: Number(r.current_balance),
      creditLimit: Number(r.credit_limit),
    }));
  }

  async summary() {
    return accountRepository.summary();
  }

  async registerPayment(payload, user) {
    const client = await accountRepository.findClient(payload.clientId);
    if (!client) throw new AppError('Cliente no encontrado.', 404);
    const amount = Number(payload.amount);
    if (!Number.isFinite(amount) || amount <= 0) throw new AppError('El monto debe ser mayor a cero.', 400);

    const payment = await accountRepository.createPayment({ ...payload, amount, userId: user.sub });
    const previous = Number(client.current_balance);
    const next = previous - amount;
    await accountRepository.updateClientBalance(client.id, next);
    await accountRepository.createMovement({
      clientId: client.id,
      movementType: 'pago',
      amount,
      previousBalance: previous,
      newBalance: next,
      description: 'Pago registrado',
      notes: payload.notes,
      userId: user.sub,
      referenceType: 'payment',
      referenceId: payment.id,
    });

    return {
      id: payment.id,
      clientId: payment.client_id,
      clientName: client.business_name,
      amount: Number(payment.amount),
      paymentMethod: payment.payment_method,
      notes: payment.notes,
      userId: payment.user_id,
      createdAt: payment.created_at,
    };
  }

  async listPayments(filters) {
    const rows = await accountRepository.listPayments(filters);
    return rows.map((r) => ({
      id: r.id,
      clientId: r.client_id,
      clientName: r.client_name,
      amount: Number(r.amount),
      paymentMethod: r.payment_method,
      notes: r.notes,
      userId: r.user_id,
      userName: r.user_name,
      createdAt: r.created_at,
    }));
  }

  async getPaymentById(id) {
    const row = await accountRepository.findPaymentById(id);
    if (!row) throw new AppError('Pago no encontrado.', 404);
    return {
      id: row.id,
      clientId: row.client_id,
      clientName: row.client_name,
      amount: Number(row.amount),
      paymentMethod: row.payment_method,
      notes: row.notes,
      userId: row.user_id,
      userName: row.user_name,
      createdAt: row.created_at,
    };
  }
}

export const accountService = new AccountService();
