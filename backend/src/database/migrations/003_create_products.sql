CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  internal_code VARCHAR(30) NOT NULL,
  name VARCHAR(180) NOT NULL,
  short_description VARCHAR(220) NOT NULL,
  long_description TEXT,
  brand VARCHAR(120) NOT NULL,
  category VARCHAR(120) NOT NULL,
  segment VARCHAR(120) NOT NULL,
  barcode VARCHAR(80),
  unit_measure VARCHAR(30) NOT NULL,
  presentation VARCHAR(80) NOT NULL,
  cost NUMERIC(14,2) NOT NULL DEFAULT 0,
  wholesale_price NUMERIC(14,2) NOT NULL DEFAULT 0,
  retail_price NUMERIC(14,2),
  margin_percentage NUMERIC(8,2),
  stock_current NUMERIC(14,3) NOT NULL DEFAULT 0,
  stock_minimum NUMERIC(14,3) NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  is_featured BOOLEAN NOT NULL DEFAULT FALSE,
  image_url TEXT,
  tax_rate NUMERIC(6,2),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deactivated_at TIMESTAMPTZ
);

ALTER TABLE products
  ADD COLUMN IF NOT EXISTS category VARCHAR(120),
  ADD COLUMN IF NOT EXISTS segment VARCHAR(120);

CREATE UNIQUE INDEX IF NOT EXISTS uq_products_internal_code ON products (internal_code);
CREATE UNIQUE INDEX IF NOT EXISTS uq_products_barcode_not_null ON products (barcode) WHERE barcode IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_products_active ON products(is_active);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_products_segment ON products(segment);
CREATE INDEX IF NOT EXISTS idx_products_brand ON products(brand);

CREATE INDEX IF NOT EXISTS idx_products_search_name ON products USING gin (name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_products_search_internal_code ON products USING gin (internal_code gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_products_search_barcode ON products USING gin (barcode gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_products_search_category ON products USING gin (category gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_products_search_brand ON products USING gin (brand gin_trgm_ops);

COMMENT ON TABLE products IS 'Catálogo de productos para ventas, stock, listas de precios y promociones';
COMMENT ON COLUMN products.margin_percentage IS 'Margen calculable en base a costo y precio mayorista';
