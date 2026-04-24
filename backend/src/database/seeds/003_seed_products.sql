INSERT INTO products (
  internal_code, name, short_description, long_description, brand, barcode,
  unit_measure, cost, wholesale_price, margin_percentage,
  stock_current, stock_minimum, is_active, is_featured, image_url, tax_rate
)
VALUES
  (
    'PRD-0001',
    'Aceite de Girasol 900ml',
    'Aceite comestible refinado',
    'Aceite de girasol apto cocina diaria, botella PET 900ml.',
    'SolDorado',
    '7790000000011',
    'Unidad',
    1200,
    1680,
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
    '7790000000028',
    'Unidad',
    480,
    720,
    50,
    90,
    30,
    TRUE,
    FALSE,
    NULL,
    21
  )
ON CONFLICT DO NOTHING;
