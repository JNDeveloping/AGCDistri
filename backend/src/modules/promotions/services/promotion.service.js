import { AppError } from '../../../errors/app-error.js';
import { pool } from '../../../database/pool.js';
import { promotionRepository } from '../repositories/promotion.repository.js';

export class PromotionService {
  list(filters){ return promotionRepository.list(filters); }
  async getById(id){ const row = await promotionRepository.findById(id); if(!row) throw new AppError('Promoción no encontrada.',404); return row; }
  async create(payload){
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const promo = await promotionRepository.create(payload);
      await promotionRepository.replaceItems(promo.id, payload.items ?? []);
      await promotionRepository.replaceTiers(promo.id, payload.tiers ?? []);
      await client.query('COMMIT');
      return this.getById(promo.id);
    } catch(e){ await client.query('ROLLBACK'); throw e; } finally { client.release(); }
  }
  async update(id,payload){ const exists = await promotionRepository.findById(id); if(!exists) throw new AppError('Promoción no encontrada.',404); const promo = await promotionRepository.update(id,payload); await promotionRepository.replaceItems(id,payload.items??[]); await promotionRepository.replaceTiers(id,payload.tiers??[]); return promo; }
  async remove(id){ const exists = await promotionRepository.findById(id); if(!exists) throw new AppError('Promoción no encontrada.',404); await promotionRepository.softDelete(id); return {id}; }
  async toggle(id){ const row = await promotionRepository.toggle(id); if(!row) throw new AppError('Promoción no encontrada.',404); return row; }
}
export const promotionService = new PromotionService();
