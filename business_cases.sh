#!/bin/bash
# Скрипт для запуска бизнес-кейсов в БД спортивного центра

DB_NAME="sport_center"
DB_USER="postgres"

echo "Запуск бизнес-кейсов..."

psql -U $DB_USER -d $DB_NAME -f business_cases.sql

echo "Бизнес-кейсы выполнены."
