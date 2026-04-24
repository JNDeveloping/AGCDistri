ALTER TABLE products
  DROP COLUMN IF EXISTS presentation,
  DROP COLUMN IF EXISTS retail_price;
