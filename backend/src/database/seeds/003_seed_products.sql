INSERT INTO products (
  internal_code, name, short_description, long_description, brand, category, segment, barcode,
  unit_measure, presentation, cost, wholesale_price, retail_price, margin_percentage,
  stock_current, stock_minimum, is_active, is_featured, image_url, tax_rate
)
VALUES
  (
    'PRD-0001',
    'Aceite de Girasol 900ml',
    'Aceite comestible refinado',
    'Aceite de girasol apto cocina diaria, botella PET 900ml.',
    'SolDorado',
    'Alimentos',
    'Aceites',
    '7790000000011',
    'unidad',
    '900 ml',
    1200,
    1680,
    1950,
    40,
    220,
    40,
    TRUE,
    TRUE,
    NULL,
    21
  ),
  (
    'PRD-0002',
    'Lavandina Tradicional',
    'Desinfectante hogar',
    NULL,
    'Limpimax',
    'Limpieza',
    'Desinfectantes',
    '7790000000028',
    'unidad',
    '1 L',
    480,
    720,
    850,
    50,
    90,
    30,
    TRUE,
    FALSE,
    NULL,
    21
  )
ON CONFLICT (internal_code) DO NOTHING;
