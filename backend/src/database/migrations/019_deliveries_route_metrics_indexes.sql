CREATE INDEX IF NOT EXISTS idx_orders_zone_delivery_status
  ON orders(client_id, status, payment_terms, updated_at);

CREATE INDEX IF NOT EXISTS idx_delivery_orders_delivery_status_updated
  ON delivery_orders(delivery_id, delivery_status, updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_delivery_orders_delivery_visit_order
  ON delivery_orders(delivery_id, visit_order);
