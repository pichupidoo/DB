#!/bin/bash
set -euo pipefail

DB_NAME="sport_center"
DB_USER="postgres"

echo ">>> Удаляем базу данных: $DB_NAME"
psql -U $DB_USER -c "DROP DATABASE IF EXISTS $DB_NAME;"
