DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'delivery_status') THEN
    CREATE TYPE delivery_status AS ENUM ('pendiente', 'en_preparacion', 'en_reparto', 'finalizado', 'cancelado');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'delivery_order_status') THEN
    CREATE TYPE delivery_order_status AS ENUM ('pendiente', 'entregado', 'no_entregado', 'reprogramado');
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS deliveries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  number BIGSERIAL UNIQUE,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  driver_id UUID REFERENCES users(id),
  status delivery_status NOT NULL DEFAULT 'pendiente',
  notes TEXT,
  zone VARCHAR(120),
  total_orders INT NOT NULL DEFAULT 0,
  total_amount NUMERIC(14,2) NOT NULL DEFAULT 0,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  finished_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS delivery_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  delivery_id UUID NOT NULL REFERENCES deliveries(id) ON DELETE CASCADE,
  order_id UUID NOT NULL REFERENCES orders(id),
  client_id UUID NOT NULL REFERENCES clients(id),
  status delivery_order_status NOT NULL DEFAULT 'pendiente',
  visit_order INT,
  notes TEXT,
  estimated_time TIMESTAMPTZ,
  not_delivered_reason TEXT,
  collected_cash BOOLEAN NOT NULL DEFAULT FALSE,
  collected_amount NUMERIC(14,2) NOT NULL DEFAULT 0,
  delivered_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_delivery_order UNIQUE(delivery_id, order_id)
);

CREATE INDEX IF NOT EXISTS idx_deliveries_date ON deliveries(date);
CREATE INDEX IF NOT EXISTS idx_deliveries_driver ON deliveries(driver_id);
CREATE INDEX IF NOT EXISTS idx_deliveries_status ON deliveries(status);
CREATE INDEX IF NOT EXISTS idx_delivery_orders_delivery ON delivery_orders(delivery_id);
CREATE INDEX IF NOT EXISTS idx_delivery_orders_order ON delivery_orders(order_id);
CREATE INDEX IF NOT EXISTS idx_delivery_orders_status ON delivery_orders(status);
