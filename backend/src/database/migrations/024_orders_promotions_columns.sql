ALTER TABLE order_items
  ADD COLUMN IF NOT EXISTS original_unit_price NUMERIC(14,2),
  ADD COLUMN IF NOT EXISTS promotion_id UUID REFERENCES promotions(id),
  ADD COLUMN IF NOT EXISTS applied_promotions JSONB;

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
