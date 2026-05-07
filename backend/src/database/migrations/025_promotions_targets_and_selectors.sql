CREATE TABLE IF NOT EXISTS promotion_targets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  promotion_id UUID NOT NULL REFERENCES promotions(id) ON DELETE CASCADE,
  product_id UUID,
  variant_id UUID,
  category_id UUID,
  client_id UUID,
  zone_id UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS promotion_combo_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  promotion_id UUID NOT NULL REFERENCES promotions(id) ON DELETE CASCADE,
  product_id UUID,
  variant_id UUID,
  required_quantity NUMERIC NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_promotion_targets_promotion_id ON promotion_targets(promotion_id);
CREATE INDEX IF NOT EXISTS idx_promotion_targets_product_id ON promotion_targets(product_id);
CREATE INDEX IF NOT EXISTS idx_promotion_targets_variant_id ON promotion_targets(variant_id);
CREATE INDEX IF NOT EXISTS idx_promotion_targets_category_id ON promotion_targets(category_id);
CREATE INDEX IF NOT EXISTS idx_promotion_targets_client_id ON promotion_targets(client_id);
CREATE INDEX IF NOT EXISTS idx_promotion_targets_zone_id ON promotion_targets(zone_id);
