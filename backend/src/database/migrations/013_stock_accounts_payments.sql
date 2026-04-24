DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'stock_movement_type') THEN
    CREATE TYPE stock_movement_type AS ENUM ('entrada', 'salida', 'ajuste', 'devolucion', 'merma', 'transferencia');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'account_movement_type') THEN
    CREATE TYPE account_movement_type AS ENUM ('deuda', 'pago', 'ajuste', 'nota_credito', 'anulacion');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_method_type') THEN
    CREATE TYPE payment_method_type AS ENUM ('efectivo', 'transferencia', 'cheque', 'mercado_pago', 'otro');
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS stock_movements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES products(id),
  movement_type stock_movement_type NOT NULL,
  quantity NUMERIC(14,3) NOT NULL CHECK (quantity > 0),
  previous_stock NUMERIC(14,3) NOT NULL,
  new_stock NUMERIC(14,3) NOT NULL,
  reason VARCHAR(180) NOT NULL,
  notes TEXT,
  user_id UUID REFERENCES users(id),
  reference_type VARCHAR(60),
  reference_id UUID,
  source_location VARCHAR(120),
  destination_location VARCHAR(120),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS account_movements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES clients(id),
  movement_type account_movement_type NOT NULL,
  amount NUMERIC(14,2) NOT NULL CHECK (amount > 0),
  previous_balance NUMERIC(14,2) NOT NULL,
  new_balance NUMERIC(14,2) NOT NULL,
  description VARCHAR(255) NOT NULL,
  notes TEXT,
  user_id UUID REFERENCES users(id),
  reference_type VARCHAR(60),
  reference_id UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS client_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES clients(id),
  amount NUMERIC(14,2) NOT NULL CHECK (amount > 0),
  payment_method payment_method_type NOT NULL,
  notes TEXT,
  user_id UUID REFERENCES users(id),
  reference_type VARCHAR(60),
  reference_id UUID,
  is_annulled BOOLEAN NOT NULL DEFAULT FALSE,
  annulled_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_stock_movements_product ON stock_movements(product_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_stock_movements_reference ON stock_movements(reference_type, reference_id);
CREATE INDEX IF NOT EXISTS idx_account_movements_client ON account_movements(client_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_account_movements_reference ON account_movements(reference_type, reference_id);
CREATE INDEX IF NOT EXISTS idx_client_payments_client ON client_payments(client_id, created_at DESC);
