ALTER TABLE deliveries
  ADD COLUMN IF NOT EXISTS zone_id UUID REFERENCES zones(id);

UPDATE deliveries d
SET zone_id = z.id
FROM zones z
WHERE d.zone_id IS NULL
  AND d.zone IS NOT NULL
  AND LOWER(z.name) = LOWER(d.zone);

CREATE INDEX IF NOT EXISTS idx_deliveries_zone_id ON deliveries(zone_id);

ALTER TABLE delivery_orders
  ADD COLUMN IF NOT EXISTS delivery_status delivery_order_status NOT NULL DEFAULT 'pendiente',
  ADD COLUMN IF NOT EXISTS amount_to_collect NUMERIC(14,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS payment_status VARCHAR(20) NOT NULL DEFAULT 'pendiente';

UPDATE delivery_orders
SET delivery_status = status
WHERE status IS NOT NULL;

UPDATE delivery_orders dor
SET amount_to_collect = COALESCE(o.total, 0)
FROM orders o
WHERE dor.order_id = o.id
  AND dor.amount_to_collect = 0;

CREATE INDEX IF NOT EXISTS idx_delivery_orders_delivery_status ON delivery_orders(delivery_status);
CREATE INDEX IF NOT EXISTS idx_delivery_orders_visit_order ON delivery_orders(delivery_id, visit_order);
CREATE INDEX IF NOT EXISTS idx_delivery_orders_payment_status ON delivery_orders(payment_status);
