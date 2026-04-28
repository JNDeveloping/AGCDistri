CREATE TABLE IF NOT EXISTS company_settings (
  id SMALLINT PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  company_name VARCHAR(180) NOT NULL DEFAULT 'AGC Distribuidora',
  logo_url TEXT,
  primary_color VARCHAR(7) NOT NULL DEFAULT '#1E4D6B',
  secondary_color VARCHAR(7) NOT NULL DEFAULT '#2FA37F',
  button_color VARCHAR(7) NOT NULL DEFAULT '#1E4D6B',
  background_color VARCHAR(7) NOT NULL DEFAULT '#F2F5F8',
  phone VARCHAR(30),
  email VARCHAR(180),
  address VARCHAR(220),
  city VARCHAR(120),
  province VARCHAR(120),
  tax_id VARCHAR(20),
  slogan VARCHAR(220),
  default_profit_percentage NUMERIC(8,2) NOT NULL DEFAULT 45,
  price_rounding_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  price_rounding_multiple INTEGER NOT NULL DEFAULT 10,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO company_settings (id)
VALUES (1)
ON CONFLICT (id) DO NOTHING;
