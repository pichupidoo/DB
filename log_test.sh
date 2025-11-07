#!/bin/bash
DB_NAME="sport_center"
SQL_FILE="/home/andrew/course4/db/test/DB/logged_vs_unlogged.sql"

echo "[$(date)] Запуск эксперимента: Logged vs Unlogged tables..."
sudo -u postgres psql -d sport_center -f log_test.sql
echo "[$(date)] Эксперимент завершён!"

