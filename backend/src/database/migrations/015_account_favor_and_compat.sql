DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_type t
    JOIN pg_enum e ON t.oid = e.enumtypid
    WHERE t.typname = 'account_movement_type'
      AND e.enumlabel = 'saldo_a_favor'
  ) THEN
    -- already exists
  ELSE
    ALTER TYPE account_movement_type ADD VALUE 'saldo_a_favor';
  END IF;
END $$;

CREATE OR REPLACE VIEW client_account_movements AS
SELECT
  id,
  client_id,
  movement_type AS type,
  amount,
  previous_balance,
  new_balance,
  reference_type,
  reference_id,
  description,
  user_id,
  created_at
FROM account_movements;
