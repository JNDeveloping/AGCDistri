UPDATE clients
SET vat_condition = 'Monotributista'
WHERE vat_condition IN ('Monotributo', 'Monotributista');

ALTER TABLE clients
  ADD CONSTRAINT chk_clients_vat_condition
  CHECK (vat_condition IN ('Responsable Inscripto', 'Monotributista'));
