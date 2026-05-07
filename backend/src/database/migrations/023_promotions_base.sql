CREATE TABLE IF NOT EXISTS promotions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  type TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ,
  priority INTEGER NOT NULL DEFAULT 0,
  stackable BOOLEAN NOT NULL DEFAULT FALSE,
  applies_to TEXT,
  discount_type TEXT,
  discount_value NUMERIC,
  fixed_price NUMERIC,
  min_quantity NUMERIC,
  min_bultos NUMERIC,
  units_per_bulto NUMERIC,
  min_order_total NUMERIC,
  client_id UUID,
  zone_id UUID,
  category_id UUID,
  product_id UUID,
  variant_id UUID,
  conditions JSONB,
  benefits JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS promotion_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  promotion_id UUID NOT NULL REFERENCES promotions(id) ON DELETE CASCADE,
  product_id UUID,
  variant_id UUID,
  category_id UUID,
  required_quantity NUMERIC NOT NULL DEFAULT 1,
  units_per_bulto NUMERIC,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS promotion_tiers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  promotion_id UUID NOT NULL REFERENCES promotions(id) ON DELETE CASCADE,
  min_quantity NUMERIC NOT NULL,
  discount_type TEXT NOT NULL,
  discount_value NUMERIC,
  fixed_unit_price NUMERIC,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS order_promotion_applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  promotion_id UUID NOT NULL REFERENCES promotions(id) ON DELETE CASCADE,
  order_item_id UUID,
  discount_amount NUMERIC NOT NULL DEFAULT 0,
  original_amount NUMERIC,
  final_amount NUMERIC,
  application_count INTEGER NOT NULL DEFAULT 1,
  metadata JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE products ADD COLUMN IF NOT EXISTS units_per_bulto NUMERIC;
ALTER TABLE product_variants ADD COLUMN IF NOT EXISTS units_per_bulto NUMERIC;

CREATE INDEX IF NOT EXISTS idx_promotions_is_active ON promotions(is_active);
CREATE INDEX IF NOT EXISTS idx_promotions_type ON promotions(type);
CREATE INDEX IF NOT EXISTS idx_promotions_product_id ON promotions(product_id);
CREATE INDEX IF NOT EXISTS idx_promotions_variant_id ON promotions(variant_id);
CREATE INDEX IF NOT EXISTS idx_promotions_category_id ON promotions(category_id);
CREATE INDEX IF NOT EXISTS idx_promotions_client_id ON promotions(client_id);
CREATE INDEX IF NOT EXISTS idx_promotions_zone_id ON promotions(zone_id);
CREATE INDEX IF NOT EXISTS idx_promotions_deleted_at ON promotions(deleted_at);
