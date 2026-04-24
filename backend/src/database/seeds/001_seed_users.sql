-- password for all users: Admin123!
INSERT INTO users (full_name, email, password_hash, role)
VALUES
  ('Administrador General', 'admin@agc.local', '$2a$12$p61vX6lFJUo3p9TXv0y2puSoA8yojGMCEezUfwTj8Vb0up5QaxXF.', 'admin'),
  ('Vendedor Demo', 'vendedor@agc.local', '$2a$12$p61vX6lFJUo3p9TXv0y2puSoA8yojGMCEezUfwTj8Vb0up5QaxXF.', 'vendedor'),
  ('Repartidor Demo', 'repartidor@agc.local', '$2a$12$p61vX6lFJUo3p9TXv0y2puSoA8yojGMCEezUfwTj8Vb0up5QaxXF.', 'repartidor')
ON CONFLICT (email) DO NOTHING;
