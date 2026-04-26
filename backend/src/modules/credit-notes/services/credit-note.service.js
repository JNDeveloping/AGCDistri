import { AppError } from '../../../errors/app-error.js';
import { accountService } from '../../accounts/services/account.service.js';
import { stockService } from '../../stock/services/stock.service.js';
import { creditNoteRepository } from '../repositories/credit-note.repository.js';

const mapCreditNote = (row, items = []) => ({
  id: row.id,
  number: Number(row.number),
  orderId: row.order_id,
  clientId: row.client_id,
  clientName: row.client_name,
  userId: row.user_id,
  userName: row.user_name,
  reason: row.reason,
  notes: row.notes,
  totalAmount: Number(row.total_amount),
  affectsStock: row.affects_stock === true,
  affectsAccount: row.affects_account === true,
  createdAt: row.created_at,
  items,
});

const mapItem = (row) => ({
  id: row.id,
  creditNoteId: row.credit_note_id,
  productId: row.product_id,
  productNameSnapshot: row.product_name_snapshot,
  quantity: Number(row.quantity),
  unitPrice: Number(row.unit_price),
  subtotal: Number(row.subtotal),
  returnToStock: row.return_to_stock === true,
  reason: row.reason,
  createdAt: row.created_at,
});

export class CreditNoteService {
  async list(filters) {
    const rows = await creditNoteRepository.list(filters);
    return rows.map((row) => mapCreditNote(row));
  }

  async getById(id) {
    const row = await creditNoteRepository.findById(id);
    if (!row) throw new AppError('Nota de crédito no encontrada.', 404);
    const items = (await creditNoteRepository.listItems(id)).map(mapItem);
    return mapCreditNote(row, items);
  }

  async listByOrder(orderId) {
    return this.list({ orderId });
  }

  async create(payload, user) {
    const order = await creditNoteRepository.findOrder(payload.orderId);
    if (!order) throw new AppError('Pedido no encontrado.', 404);
    if (order.status !== 'entregado') {
      throw new AppError('Solo se pueden crear notas de crédito para pedidos entregados.', 409);
    }

    const orderItems = await creditNoteRepository.listOrderItems(order.id);
    const soldByProduct = new Map(orderItems.map((item) => [item.product_id, Number(item.quantity)]));

    const creditedRows = await creditNoteRepository.getCreditedByProduct(order.id);
    const creditedByProduct = new Map(creditedRows.map((row) => [row.product_id, Number(row.credited_quantity)]));

    const normalizedItems = payload.items.map((item) => {
      const soldQty = soldByProduct.get(item.productId);
      if (soldQty == null) {
        throw new AppError(`El producto ${item.productNameSnapshot} no pertenece al pedido.`, 400);
      }
      const qty = Number(item.quantity);
      if (!Number.isFinite(qty) || qty <= 0) throw new AppError('Las cantidades deben ser mayores a cero.', 400);
      const alreadyCredited = creditedByProduct.get(item.productId) ?? 0;
      if (qty + alreadyCredited > soldQty) {
        throw new AppError(`No se puede acreditar más de lo vendido para ${item.productNameSnapshot}.`, 409);
      }
      const unitPrice = Number(item.unitPrice);
      const subtotal = Number((qty * unitPrice).toFixed(2));
      return { ...item, quantity: qty, unitPrice, subtotal };
    });

    const totalAmount = normalizedItems.reduce((acc, item) => acc + item.subtotal, 0);
    const affectsStock = payload.affectsStock === true;
    const affectsAccount = payload.affectsAccount !== false && order.payment_terms === 'cuenta_corriente';

    const note = await creditNoteRepository.createWithItems({
      orderId: order.id,
      clientId: order.client_id,
      userId: user.sub,
      reason: payload.reason,
      notes: payload.notes,
      totalAmount,
      affectsStock,
      affectsAccount,
      items: normalizedItems,
    });

    if (affectsStock) {
      for (const item of normalizedItems) {
        if (!item.returnToStock) continue;
        await stockService.createMovement(
          {
            productId: item.productId,
            movementType: 'devolucion',
            quantity: item.quantity,
            reason: `Devolución por nota de crédito #${note.number}`,
            notes: item.reason ?? payload.reason,
            referenceType: 'credit_note',
            referenceId: note.id,
          },
          user,
        );
      }
    }

    if (affectsAccount) {
      await accountService.createMovement(
        order.client_id,
        {
          movementType: 'nota_credito',
          amount: totalAmount,
          description: `Nota de crédito #${note.number}`,
          notes: payload.notes,
          referenceType: 'credit_note',
          referenceId: note.id,
        },
        user,
      );
    }

    return this.getById(note.id);
  }
}

export const creditNoteService = new CreditNoteService();

