#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${DATABASE_URL:-}" ]]; then
  echo "DATABASE_URL is required"
  exit 1
fi

for file in src/database/seeds/*.sql; do
  echo "Applying seed: $file"
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$file"
done
