ALTER TABLE products
  ADD COLUMN IF NOT EXISTS has_variants BOOLEAN NOT NULL DEFAULT FALSE;

CREATE TABLE IF NOT EXISTS product_variants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  name VARCHAR(180) NOT NULL,
  internal_code VARCHAR(60),
  barcode VARCHAR(80),
  price NUMERIC(14, 2),
  cost NUMERIC(14, 2),
  stock NUMERIC(14, 3),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deactivated_at TIMESTAMPTZ
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_product_variants_unique_name
  ON product_variants(product_id, LOWER(name));

ALTER TABLE stock_movements
  ADD COLUMN IF NOT EXISTS product_variant_id UUID REFERENCES product_variants(id);

ALTER TABLE order_items
  ADD COLUMN IF NOT EXISTS product_variant_id UUID REFERENCES product_variants(id),
  ADD COLUMN IF NOT EXISTS product_name_snapshot VARCHAR(220),
  ADD COLUMN IF NOT EXISTS variant_name_snapshot VARCHAR(220);

CREATE TABLE IF NOT EXISTS credit_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  number BIGINT NOT NULL UNIQUE,
  order_id UUID NOT NULL REFERENCES orders(id),
  client_id UUID NOT NULL REFERENCES clients(id),
  user_id UUID NOT NULL REFERENCES users(id),
  reason VARCHAR(220) NOT NULL,
  notes TEXT,
  total_amount NUMERIC(14, 2) NOT NULL DEFAULT 0,
  affects_stock BOOLEAN NOT NULL DEFAULT FALSE,
  affects_account BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS credit_note_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  credit_note_id UUID NOT NULL REFERENCES credit_notes(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id),
  product_name_snapshot VARCHAR(220) NOT NULL,
  quantity NUMERIC(14, 3) NOT NULL,
  unit_price NUMERIC(14, 2) NOT NULL,
  subtotal NUMERIC(14, 2) NOT NULL,
  return_to_stock BOOLEAN NOT NULL DEFAULT FALSE,
  reason VARCHAR(220),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_credit_notes_order ON credit_notes(order_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_credit_notes_client ON credit_notes(client_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_credit_note_items_note ON credit_note_items(credit_note_id);

