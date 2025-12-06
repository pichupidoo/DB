#!/bin/bash

DB="sport_center"
TABLE="bookings_copy"
PART_TABLE="booking_partitioned"
CONTAINER="pg_main" # имя контейнера с PostgreSQL

PART_SIZE=500000  # количество записей на партицию
TOTAL_ROWS=3200000  # общее количество записей, можно подогнать
NUM_PARTS=$(( (TOTAL_ROWS + PART_SIZE - 1) / PART_SIZE ))  # число партиций, округляем вверх

# Функция для выполнения psql внутри контейнера
exec_psql() {
    docker exec -u postgres $CONTAINER psql -U postgres -d $DB -c "$1"
}

echo "Удаляем старую партиционированную таблицу, если есть..."
exec_psql "DROP TABLE IF EXISTS $PART_TABLE CASCADE;"

echo "Создаём родительскую таблицу..."
exec_psql "
CREATE TABLE $PART_TABLE (
    booking_id INT PRIMARY KEY,
    client_id INT,
    class_id INT,
    status TEXT
) PARTITION BY RANGE (booking_id);
"

# Создаём партиции
CURRENT_MIN=1
for PART_NUM in $(seq 1 $NUM_PARTS); do
    CURRENT_MAX=$(( CURRENT_MIN + PART_SIZE ))
    if [ $CURRENT_MAX -gt $((TOTAL_ROWS + 1)) ]; then
        CURRENT_MAX=$((TOTAL_ROWS + 1))
    fi
    PART_NAME="${PART_TABLE}_part${PART_NUM}"
    echo "Создаём партицию $PART_NAME FOR VALUES FROM ($CURRENT_MIN) TO ($CURRENT_MAX)"
    exec_psql "CREATE TABLE $PART_NAME PARTITION OF $PART_TABLE FOR VALUES FROM ($CURRENT_MIN) TO ($CURRENT_MAX);"
    CURRENT_MIN=$CURRENT_MAX
done

# Переносим данные
echo "Переносим данные в партиционированную таблицу..."
exec_psql "INSERT INTO $PART_TABLE SELECT * FROM $TABLE;"

# Экспериментальные запросы
echo "EXPLAIN ANALYZE для диапазона по booking_id..."
exec_psql "EXPLAIN ANALYZE SELECT * FROM $PART_TABLE WHERE booking_id BETWEEN 1000000 AND 1100000;"
exec_psql "EXPLAIN ANALYZE SELECT * FROM $TABLE WHERE booking_id BETWEEN 1000000 AND 1100000;"

echo "EXPLAIN ANALYZE для условия по статусу..."
exec_psql "EXPLAIN ANALYZE SELECT * FROM $PART_TABLE WHERE status='посетил';"
exec_psql "EXPLAIN ANALYZE SELECT * FROM $TABLE WHERE status='посетил';"
echo "EXPLAIN ANALYZE для нижнего диапазона..."
exec_psql "EXPLAIN ANALYZE SELECT * FROM $PART_TABLE WHERE booking_id BETWEEN 1 AND 50000;"
exec_psql "EXPLAIN ANALYZE SELECT * FROM $TABLE WHERE booking_id BETWEEN 1 AND 50000;"

echo "EXPLAIN ANALYZE для верхнего диапазона..."
exec_psql "EXPLAIN ANALYZE SELECT * FROM $PART_TABLE WHERE booking_id BETWEEN 3150000 AND 3200000;"
exec_psql "EXPLAIN ANALYZE SELECT * FROM $TABLE WHERE booking_id BETWEEN 3150000 AND 3200000;"

echo "EXPLAIN ANALYZE для смешанного условия..."
exec_psql "EXPLAIN ANALYZE SELECT * FROM $PART_TABLE WHERE booking_id BETWEEN 1000000 AND 1500000 AND status='посетил';"
exec_psql "EXPLAIN ANALYZE SELECT * FROM $TABLE WHERE booking_id BETWEEN 1000000 AND 1500000 AND status='посетил';"



echo "Скрипт завершён успешно!"
