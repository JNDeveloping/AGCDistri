import { AppError } from '../../../errors/app-error.js';
import { companySettingsRepository } from '../repositories/company-settings.repository.js';

const DEFAULT_SETTINGS = {
  companyName: 'AGC Distribuidora',
  logoUrl: null,
  primaryColor: '#1E4D6B',
  secondaryColor: '#2FA37F',
  buttonColor: '#1E4D6B',
  backgroundColor: '#F2F5F8',
  phone: null,
  email: null,
  address: null,
  city: null,
  province: null,
  taxId: null,
  slogan: null,
  defaultProfitPercentage: 45,
  priceRoundingEnabled: true,
  priceRoundingMultiple: 10,
};

const toRgb = (hex) => {
  const value = hex.replace('#', '');
  const bigint = Number.parseInt(value, 16);
  return {
    r: (bigint >> 16) & 255,
    g: (bigint >> 8) & 255,
    b: bigint & 255,
  };
};

const luminance = ({ r, g, b }) => {
  const channel = [r, g, b].map((c) => {
    const v = c / 255;
    return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4;
  });

  return 0.2126 * channel[0] + 0.7152 * channel[1] + 0.0722 * channel[2];
};

const contrastRatio = (hexA, hexB) => {
  const l1 = luminance(toRgb(hexA));
  const l2 = luminance(toRgb(hexB));
  const brightest = Math.max(l1, l2);
  const darkest = Math.min(l1, l2);
  return (brightest + 0.05) / (darkest + 0.05);
};

const mapRow = (row) => ({
  companyName: row.company_name,
  logoUrl: row.logo_url,
  primaryColor: row.primary_color,
  secondaryColor: row.secondary_color,
  buttonColor: row.button_color,
  backgroundColor: row.background_color,
  phone: row.phone,
  email: row.email,
  address: row.address,
  city: row.city,
  province: row.province,
  taxId: row.tax_id,
  slogan: row.slogan,
  defaultProfitPercentage: Number(row.default_profit_percentage),
  priceRoundingEnabled: row.price_rounding_enabled,
  priceRoundingMultiple: Number(row.price_rounding_multiple),
  createdAt: row.created_at,
  updatedAt: row.updated_at,
});

const sanitizeOptional = (value) => {
  if (value === undefined || value === null) return null;
  const trimmed = String(value).trim();
  return trimmed.length ? trimmed : null;
};

export class CompanySettingsService {
  async get() {
    const row = await companySettingsRepository.get();
    if (!row) {
      const created = await companySettingsRepository.upsert(DEFAULT_SETTINGS);
      return mapRow(created);
    }

    return mapRow(row);
  }

  async upsert(payload) {
    const previous = await this.get();
    const merged = {
      ...previous,
      ...payload,
      companyName: payload.companyName ?? previous.companyName,
      primaryColor: payload.primaryColor ?? previous.primaryColor,
      secondaryColor: payload.secondaryColor ?? previous.secondaryColor,
      buttonColor: payload.buttonColor ?? previous.buttonColor,
      backgroundColor: payload.backgroundColor ?? previous.backgroundColor,
      logoUrl: sanitizeOptional(payload.logoUrl ?? previous.logoUrl),
      phone: sanitizeOptional(payload.phone ?? previous.phone),
      email: sanitizeOptional(payload.email ?? previous.email),
      address: sanitizeOptional(payload.address ?? previous.address),
      city: sanitizeOptional(payload.city ?? previous.city),
      province: sanitizeOptional(payload.province ?? previous.province),
      taxId: sanitizeOptional(payload.taxId ?? previous.taxId),
      slogan: sanitizeOptional(payload.slogan ?? previous.slogan),
      defaultProfitPercentage: payload.defaultProfitPercentage ?? previous.defaultProfitPercentage,
      priceRoundingEnabled: payload.priceRoundingEnabled ?? previous.priceRoundingEnabled,
      priceRoundingMultiple: payload.priceRoundingMultiple ?? previous.priceRoundingMultiple,
    };

    const contrastPrimary = contrastRatio(merged.primaryColor, merged.backgroundColor);
    const contrastButton = contrastRatio(merged.buttonColor, merged.backgroundColor);

    if (contrastPrimary < 2.5 || contrastButton < 2.5) {
      throw new AppError('Los colores seleccionados no tienen contraste suficiente para una UI legible.', 400, {
        contrastPrimary,
        contrastButton,
      });
    }

    const saved = await companySettingsRepository.upsert(merged);
    return mapRow(saved);
  }

  async resetDefaults() {
    const saved = await companySettingsRepository.upsert(DEFAULT_SETTINGS);
    return mapRow(saved);
  }
}

export const companySettingsService = new CompanySettingsService();
