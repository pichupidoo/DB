#!/bin/bash

DB="sport_center"
CONTAINER="pg_main"

# Размер эксперимента
NUM_ROWS=2000000

# Функция для выполнения SQL в контейнере
exec_psql() {
    docker exec -u postgres $CONTAINER psql -U postgres -d $DB -c "$1"
}

echo "Удаляем старые таблицы, если есть..."
exec_psql "DROP TABLE IF EXISTS logged_table;"
exec_psql "DROP TABLE IF EXISTS unlogged_table;"

echo "Создаём logged и unlogged таблицы..."
exec_psql "CREATE TABLE logged_table (id SERIAL PRIMARY KEY, value TEXT);"
exec_psql "CREATE UNLOGGED TABLE unlogged_table (id SERIAL PRIMARY KEY, value TEXT);"

echo "Вставка $NUM_ROWS записей по одной (может быть медленно)..."
echo "Logged table:"
time docker exec -u postgres $CONTAINER psql -U postgres -d $DB -c "
DO \$\$
BEGIN
  FOR i IN 1..$NUM_ROWS LOOP
    INSERT INTO logged_table(value) VALUES ('test');
  END LOOP;
END
\$\$;"

echo "Unlogged table:"
time docker exec -u postgres $CONTAINER psql -U postgres -d $DB -c "
DO \$\$
BEGIN
  FOR i IN 1..$NUM_ROWS LOOP
    INSERT INTO unlogged_table(value) VALUES ('test');
  END LOOP;
END
\$\$;"

echo "Вставка $NUM_ROWS записей пакетом..."
echo "Logged table:"
time exec_psql "INSERT INTO logged_table (value) SELECT 'test' FROM generate_series(1,$NUM_ROWS);"

echo "Unlogged table:"
time exec_psql "INSERT INTO unlogged_table (value) SELECT 'test' FROM generate_series(1,$NUM_ROWS);"

echo "Вставка одного элемента..."
time exec_psql "INSERT INTO logged_table(value) VALUES ('single_test');"
time exec_psql "INSERT INTO unlogged_table(value) VALUES ('single_test');"

echo "Удаление одного элемента..."
time exec_psql "DELETE FROM logged_table WHERE value='single_test';"
time exec_psql "DELETE FROM unlogged_table WHERE value='single_test';"

echo "Unlogged table:"
time exec_psql "SELECT COUNT(*) FROM unlogged_table;"

echo "Удаление всех записей..."
echo "Logged table:"
time exec_psql "DELETE FROM logged_table;"

echo "Unlogged table:"
time exec_psql "DELETE FROM unlogged_table;"

echo "Эксперимент завершён!"
