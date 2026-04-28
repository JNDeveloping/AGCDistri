DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'order_status') THEN
    CREATE TYPE order_status AS ENUM ('pendiente', 'confirmado', 'preparado', 'en_reparto', 'entregado', 'cancelado');
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_number BIGSERIAL UNIQUE,
  client_id UUID NOT NULL REFERENCES clients(id),
  seller_id UUID NOT NULL REFERENCES users(id),
  assigned_delivery_user_id UUID REFERENCES users(id),
  order_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  status order_status NOT NULL DEFAULT 'pendiente',
  notes TEXT,
  payment_terms VARCHAR(120),
  subtotal NUMERIC(14,2) NOT NULL DEFAULT 0,
  discount_total NUMERIC(14,2) NOT NULL DEFAULT 0,
  tax_total NUMERIC(14,2) NOT NULL DEFAULT 0,
  total NUMERIC(14,2) NOT NULL DEFAULT 0,
  estimated_margin NUMERIC(14,2) NOT NULL DEFAULT 0,
  delivery_address VARCHAR(255),
  estimated_delivery_date DATE,
  stock_discounted BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  canceled_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id),
  product_code VARCHAR(30),
  product_name VARCHAR(180) NOT NULL,
  quantity NUMERIC(12,3) NOT NULL,
  unit_measure VARCHAR(30),
  unit_price NUMERIC(14,2) NOT NULL,
  discount_amount NUMERIC(14,2) NOT NULL DEFAULT 0,
  subtotal NUMERIC(14,2) NOT NULL,
  cost NUMERIC(14,2),
  estimated_margin NUMERIC(14,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_orders_client_id ON orders(client_id);
CREATE INDEX IF NOT EXISTS idx_orders_seller_id ON orders(seller_id);
CREATE INDEX IF NOT EXISTS idx_orders_delivery_user_id ON orders(assigned_delivery_user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_order_date ON orders(order_date);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
