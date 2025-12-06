#!/bin/bash
# Скрипт для резервного копирования PostgreSQL

DATE=$(date +"%Y%m%d_%H%M")
BACKUP_DIR="/home/andrew/course4/db/dockerdb/backups"
mkdir -p $BACKUP_DIR

docker exec -u postgres pg_main pg_dumpall -U postgres -f /var/lib/postgresql/data/full_backup.sql
docker cp pg_main:/var/lib/postgresql/data/full_backup.sql $BACKUP_DIR/full_backup_$DATE.sql

echo "Backup created at $BACKUP_DIR/full_backup_$DATE.sql"

echo "$(date '+%Y-%m-%d %H:%M:%S') Backup created: $BACKUP_DIR/full_backup_$DATE.sql"
