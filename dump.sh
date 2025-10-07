#!/bin/bash

# Имя базы данных
DB_NAME="sport_center"

# Имя файла дампа в текущей папке
DUMP_FILE="./${DB_NAME}.dump"

# Пользователь PostgreSQL
PG_USER="postgres"

echo "=== Шаг 1: Создание дампа базы данных ==="
# Проверяем права записи для postgres
sudo -u $PG_USER touch "$DUMP_FILE" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Ошибка: пользователь postgres не имеет прав на запись в текущую директорию."
    exit 1
fi
# Удаляем тестовый файл
sudo -u $PG_USER rm -f "$DUMP_FILE"

sudo -u $PG_USER pg_dump -F c -b -v -f "$DUMP_FILE" $DB_NAME
if [ $? -ne 0 ]; then
    echo "Ошибка при создании дампа. Прерывание."
    exit 1
fi
echo "Дамп успешно создан: $DUMP_FILE"

echo "=== Шаг 2: Удаление базы данных ==="
sudo -u $PG_USER psql -c "DROP DATABASE IF EXISTS $DB_NAME;"
if [ $? -ne 0 ]; then
    echo "Ошибка при удалении базы данных. Прерывание."
    exit 1
fi
echo "База данных удалена."

echo "=== Шаг 3: Создание пустой базы для восстановления ==="
sudo -u $PG_USER psql -c "CREATE DATABASE $DB_NAME;"
if [ $? -ne 0 ]; then
    echo "Ошибка при создании базы данных. Прерывание."
    exit 1
fi
echo "База данных создана."

echo "=== Шаг 4: Восстановление базы из дампа ==="
sudo -u $PG_USER pg_restore -d $DB_NAME -v "$DUMP_FILE"
if [ $? -ne 0 ]; then
    echo "Ошибка при восстановлении базы данных. Прерывание."
    exit 1
fi
echo "База данных успешно восстановлена из дампа."

echo "=== Процесс завершён успешно ==="
