CREATE TABLE IF NOT EXISTS zones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(120) NOT NULL,
  description TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deactivated_at TIMESTAMPTZ
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_zones_name_lower ON zones (LOWER(name));
CREATE INDEX IF NOT EXISTS idx_zones_active ON zones (is_active);

ALTER TABLE clients ADD COLUMN IF NOT EXISTS zone_id UUID;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE constraint_name = 'fk_clients_zone_id'
      AND table_name = 'clients'
  ) THEN
    ALTER TABLE clients
      ADD CONSTRAINT fk_clients_zone_id
      FOREIGN KEY (zone_id)
      REFERENCES zones(id)
      ON DELETE SET NULL;
  END IF;
END $$;

INSERT INTO zones (name)
SELECT DISTINCT route_zone
FROM clients
WHERE route_zone IS NOT NULL
  AND TRIM(route_zone) <> ''
ON CONFLICT ((LOWER(name))) DO NOTHING;

UPDATE clients c
SET zone_id = z.id
FROM zones z
WHERE c.zone_id IS NULL
  AND c.route_zone IS NOT NULL
  AND LOWER(TRIM(c.route_zone)) = LOWER(TRIM(z.name));
