DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_name = 'products'
      AND column_name = 'presentation'
  ) THEN
    COMMENT ON COLUMN products.presentation IS 'Campo legado: se mantiene por compatibilidad y para preservar datos históricos';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_name = 'products'
      AND column_name = 'retail_price'
  ) THEN
    COMMENT ON COLUMN products.retail_price IS 'Campo legado: se mantiene por compatibilidad y para preservar datos históricos';
  END IF;
END $$;
