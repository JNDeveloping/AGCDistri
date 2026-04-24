import { pool } from '../../../database/pool.js';

export class CompanySettingsRepository {
  async get() {
    const { rows } = await pool.query('SELECT * FROM company_settings WHERE id = 1 LIMIT 1');
    return rows[0] ?? null;
  }

  async upsert(payload) {
    const query = `
      INSERT INTO company_settings (
        id, company_name, logo_url, primary_color, secondary_color, button_color,
        background_color, phone, email, address, city, province, tax_id, slogan,
        default_profit_percentage, price_rounding_enabled, price_rounding_multiple
      ) VALUES (
        1, $1, $2, $3, $4, $5,
        $6, $7, $8, $9, $10, $11, $12, $13,
        $14, $15, $16
      )
      ON CONFLICT (id)
      DO UPDATE SET
        company_name = EXCLUDED.company_name,
        logo_url = EXCLUDED.logo_url,
        primary_color = EXCLUDED.primary_color,
        secondary_color = EXCLUDED.secondary_color,
        button_color = EXCLUDED.button_color,
        background_color = EXCLUDED.background_color,
        phone = EXCLUDED.phone,
        email = EXCLUDED.email,
        address = EXCLUDED.address,
        city = EXCLUDED.city,
        province = EXCLUDED.province,
        tax_id = EXCLUDED.tax_id,
        slogan = EXCLUDED.slogan,
        default_profit_percentage = EXCLUDED.default_profit_percentage,
        price_rounding_enabled = EXCLUDED.price_rounding_enabled,
        price_rounding_multiple = EXCLUDED.price_rounding_multiple,
        updated_at = NOW()
      RETURNING *
    `;

    const values = [
      payload.companyName,
      payload.logoUrl,
      payload.primaryColor,
      payload.secondaryColor,
      payload.buttonColor,
      payload.backgroundColor,
      payload.phone,
      payload.email,
      payload.address,
      payload.city,
      payload.province,
      payload.taxId,
      payload.slogan,
      payload.defaultProfitPercentage,
      payload.priceRoundingEnabled,
      payload.priceRoundingMultiple,
    ];

    const { rows } = await pool.query(query, values);
    return rows[0] ?? null;
  }
}

export const companySettingsRepository = new CompanySettingsRepository();
