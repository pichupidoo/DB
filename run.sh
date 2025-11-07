#!/bin/bash
set -euo pipefail

DB_NAME="sport_center"
DB_USER="postgres"

echo ">>> Создаём базу данных: $DB_NAME"
psql -U $DB_USER -c "DROP DATABASE IF EXISTS $DB_NAME;"
psql -U $DB_USER -c "CREATE DATABASE $DB_NAME;"

echo ">>> Накатываем физическую модель..."
psql -U $DB_USER -d $DB_NAME -f physical_model.sql

echo ">>> Заполняем тестовыми данными..."
psql -U $DB_USER -d $DB_NAME -f fill_data.sql

echo ">>> База данных успешно создана и заполнена!"
