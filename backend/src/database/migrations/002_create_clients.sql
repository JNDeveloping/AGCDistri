CREATE EXTENSION IF NOT EXISTS "pg_trgm";

CREATE TABLE IF NOT EXISTS clients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  internal_code VARCHAR(30) NOT NULL,
  business_name VARCHAR(180) NOT NULL,
  contact_name VARCHAR(120) NOT NULL,
  phone VARCHAR(30) NOT NULL,
  alternate_phone VARCHAR(30),
  email VARCHAR(180),
  tax_id VARCHAR(20),
  address_line VARCHAR(220) NOT NULL,
  city VARCHAR(120) NOT NULL,
  province VARCHAR(120) NOT NULL,
  route_zone VARCHAR(80) NOT NULL,
  notes TEXT,
  vat_condition VARCHAR(80) NOT NULL,
  credit_limit NUMERIC(14,2) NOT NULL DEFAULT 0,
  current_balance NUMERIC(14,2) NOT NULL DEFAULT 0,
  latitude NUMERIC(10,7),
  longitude NUMERIC(10,7),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deactivated_at TIMESTAMPTZ
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_clients_internal_code ON clients (internal_code);
CREATE UNIQUE INDEX IF NOT EXISTS uq_clients_tax_id_not_null ON clients (tax_id) WHERE tax_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_clients_city ON clients (city);
CREATE INDEX IF NOT EXISTS idx_clients_route_zone ON clients (route_zone);
CREATE INDEX IF NOT EXISTS idx_clients_active ON clients (is_active);

CREATE INDEX IF NOT EXISTS idx_clients_search_business_name ON clients USING gin (business_name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_clients_search_contact_name ON clients USING gin (contact_name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_clients_search_phone ON clients USING gin (phone gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_clients_search_city ON clients USING gin (city gin_trgm_ops);

COMMENT ON TABLE clients IS 'Clientes comerciales para ventas, pedidos, cuentas corrientes y logística';
COMMENT ON COLUMN clients.route_zone IS 'Zona/ruta logística para armado futuro de hoja de ruta';
COMMENT ON COLUMN clients.current_balance IS 'Saldo de cuenta corriente para cobranzas futuras';
