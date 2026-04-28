DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_name = 'products'
      AND column_name = 'short_description'
      AND is_nullable = 'NO'
  ) THEN
    ALTER TABLE products ALTER COLUMN short_description DROP NOT NULL;
  END IF;
END $$;
