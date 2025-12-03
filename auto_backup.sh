#!/bin/bash
# ------------------------------------------------------------------
# Автоматический бэкап PostgreSQL базы и настроек
# ------------------------------------------------------------------

# Настройки
BACKUP_DIR="/var/backups/postgresql"
DATE=$(date +%F)
PG_USER="postgres"
DB_NAME="sport_center"
PG_VERSION="14"  # версия кластера
PG_CONF_DIR="/etc/postgresql/$PG_VERSION/main"

# ------------------------------------------------------------------
# Подготовка каталога для бэкапов
# ------------------------------------------------------------------
sudo mkdir -p "$BACKUP_DIR"
sudo chown -R $PG_USER:$PG_USER "$BACKUP_DIR"

echo "[$(date)] Starting PostgreSQL backup..."

# ------------------------------------------------------------------
# 1 Дамп базы в custom-формате
# ------------------------------------------------------------------
PG_DUMP_FILE="$BACKUP_DIR/${DB_NAME}_$DATE.dump"
cd /tmp || exit 1
sudo -u $PG_USER pg_dump -Fc -f "$PG_DUMP_FILE" "$DB_NAME"
echo "[$(date)] Database dump saved to $PG_DUMP_FILE"

# ------------------------------------------------------------------
# 2 Дамп ролей и глобальных объектов (исправлено!)
# ------------------------------------------------------------------
PG_ROLES_FILE="$BACKUP_DIR/roles_$DATE.sql"
sudo -u $PG_USER bash -c "pg_dumpall --globals-only > '$PG_ROLES_FILE'"
echo "[$(date)] Roles and global objects dump saved to $PG_ROLES_FILE"

# ------------------------------------------------------------------
# 3 Копируем конфигурационные файлы PostgreSQL
# ------------------------------------------------------------------
sudo cp "$PG_CONF_DIR/postgresql.conf" "$BACKUP_DIR/postgresql.conf_$DATE"
sudo cp "$PG_CONF_DIR/pg_hba.conf" "$BACKUP_DIR/pg_hba.conf_$DATE"
sudo cp "$PG_CONF_DIR/pg_ident.conf" "$BACKUP_DIR/pg_ident.conf_$DATE"
echo "[$(date)] Configuration files copied"

# ------------------------------------------------------------------
# 4 Очистка старых бэкапов (например, старше 7 дней)
# ------------------------------------------------------------------
sudo find "$BACKUP_DIR" -type f -mtime +7 -exec rm -f {} \;
echo "[$(date)] Old backups removed (older than 7 days)"

echo "[$(date)] PostgreSQL backup completed successfully!"
