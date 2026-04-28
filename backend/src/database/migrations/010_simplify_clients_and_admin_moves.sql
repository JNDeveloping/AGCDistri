ALTER TABLE clients DROP COLUMN IF EXISTS contact_name;
ALTER TABLE clients DROP COLUMN IF EXISTS alternate_phone;

DROP INDEX IF EXISTS idx_clients_search_contact_name;
