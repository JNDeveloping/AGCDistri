CREATE TABLE IF NOT EXISTS product_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(120) NOT NULL,
  description TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deactivated_at TIMESTAMPTZ
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_product_categories_name ON product_categories (LOWER(name));

INSERT INTO product_categories (name)
SELECT DISTINCT category
FROM products
WHERE category IS NOT NULL AND TRIM(category) <> ''
ON CONFLICT ((LOWER(name))) DO NOTHING;

ALTER TABLE products
  ADD COLUMN IF NOT EXISTS category_id UUID,
  ADD COLUMN IF NOT EXISTS notes TEXT;

UPDATE products p
SET category_id = c.id
FROM product_categories c
WHERE p.category_id IS NULL
AND p.category IS NOT NULL
AND LOWER(TRIM(p.category)) = LOWER(TRIM(c.name));

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'fk_products_category_id'
      AND table_name = 'products'
  ) THEN
    ALTER TABLE products
      ADD CONSTRAINT fk_products_category_id
      FOREIGN KEY (category_id)
      REFERENCES product_categories(id)
      ON DELETE SET NULL;
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'internal_code') THEN
    ALTER TABLE products ALTER COLUMN internal_code DROP NOT NULL;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'brand') THEN
    ALTER TABLE products ALTER COLUMN brand DROP NOT NULL;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'category') THEN
    ALTER TABLE products ALTER COLUMN category DROP NOT NULL;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'segment') THEN
    ALTER TABLE products ALTER COLUMN segment DROP NOT NULL;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'unit_measure') THEN
    ALTER TABLE products ALTER COLUMN unit_measure DROP NOT NULL;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'presentation') THEN
    ALTER TABLE products ALTER COLUMN presentation DROP NOT NULL;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'cost') THEN
    ALTER TABLE products ALTER COLUMN cost DROP NOT NULL;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'wholesale_price') THEN
    ALTER TABLE products ALTER COLUMN wholesale_price DROP NOT NULL;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'stock_current') THEN
    ALTER TABLE products ALTER COLUMN stock_current DROP NOT NULL;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'stock_minimum') THEN
    ALTER TABLE products ALTER COLUMN stock_minimum DROP NOT NULL;
  END IF;
END $$;

UPDATE products SET internal_code = NULL WHERE internal_code = '';
UPDATE products SET barcode = NULL WHERE barcode = '';
UPDATE products SET unit_measure = NULL WHERE unit_measure = '';

DROP INDEX IF EXISTS uq_products_internal_code;
CREATE UNIQUE INDEX IF NOT EXISTS uq_products_internal_code_not_null ON products (internal_code) WHERE internal_code IS NOT NULL;

DROP INDEX IF EXISTS uq_products_barcode_not_null;
CREATE UNIQUE INDEX IF NOT EXISTS uq_products_barcode_not_null ON products (barcode) WHERE barcode IS NOT NULL;

ALTER TABLE products DROP COLUMN IF EXISTS segment;
ALTER TABLE products DROP COLUMN IF EXISTS category;
