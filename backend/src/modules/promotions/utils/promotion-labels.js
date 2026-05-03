export const promotionTypeLabel = (type) => ({
  quantity_discount: 'Descuento por unidades',
  bulk_discount: 'Descuento por bultos',
  tiered_discount: 'Descuento escalonado',
  combo: 'Combo de productos',
  x_for_y: 'Llevá X pagá Y',
  order_total_discount: 'Descuento por monto total',
  target_discount: 'Descuento por cliente/zona',
  stock_discount: 'Liquidación por stock',
}[type] ?? type);

export const discountTypeLabel = (type) => ({
  percentage: 'Porcentaje',
  fixed_amount: 'Monto fijo',
  fixed_price: 'Precio especial',
}[type] ?? type ?? null);

export const promotionSummary = (row) => {
  if (row.discount_type === 'percentage' && row.discount_value != null) return `${Number(row.discount_value)}% de descuento`;
  if (row.discount_type === 'fixed_amount' && row.discount_value != null) return `$${Number(row.discount_value)} de descuento`;
  if (row.discount_type === 'fixed_price' && row.fixed_price != null) return `Precio especial $${Number(row.fixed_price)}`;
  return 'Sin resumen de beneficio';
};
