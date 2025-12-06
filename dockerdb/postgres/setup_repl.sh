#!/bin/bash

set -e

MASTER_CONTAINER="pg_main"
REPLICA_CONTAINER="pg_sub"
REPLICA_VOLUME="sub_data"
REPLICATION_USER="replicator"
REPLICATION_PASSWORD="replicator_pass"

echo "Starting master and replica containers..."
docker compose up -d 

echo "Waiting for master to be ready..."
until docker exec -u postgres $MASTER_CONTAINER pg_isready -U postgres > /dev/null 2>&1; do
    sleep 2
done

echo "Configuring master for replication..."
docker exec -u postgres $MASTER_CONTAINER bash -c "
sed -i 's/^#wal_level = .*/wal_level = replica/' /var/lib/postgresql/data/postgresql.conf
sed -i 's/^#max_wal_senders = .*/max_wal_senders = 10/' /var/lib/postgresql/data/postgresql.conf
sed -i 's/^#wal_keep_size = .*/wal_keep_size = 64/' /var/lib/postgresql/data/postgresql.conf
echo 'host replication $REPLICATION_USER 0.0.0.0/0 md5' >> /var/lib/postgresql/data/pg_hba.conf

# НАСТРОЙКИ ДЛЯ МОНИТОРИНГА И ОПТИМИЗАЦИИ ТОЛЬКО НА МАСТЕРЕ
echo \"# Monitoring and optimization settings\" >> /var/lib/postgresql/data/postgresql.conf
echo \"shared_preload_libraries = 'pg_stat_statements'\" >> /var/lib/postgresql/data/postgresql.conf
echo \"pg_stat_statements.track = all\" >> /var/lib/postgresql/data/postgresql.conf
echo \"pg_stat_statements.max = 10000\" >> /var/lib/postgresql/data/postgresql.conf
echo \"pg_stat_statements.track_utility = on\" >> /var/lib/postgresql/data/postgresql.conf
echo \"track_activities = on\" >> /var/lib/postgresql/data/postgresql.conf
echo \"track_counts = on\" >> /var/lib/postgresql/data/postgresql.conf
echo \"track_io_timing = on\" >> /var/lib/postgresql/data/postgresql.conf

pg_ctl -D /var/lib/postgresql/data reload
"

echo "Creating replication user on master..."
docker exec -u postgres $MASTER_CONTAINER psql -U postgres -c "DO \$\$ 
BEGIN
   IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$REPLICATION_USER') THEN
      CREATE ROLE $REPLICATION_USER REPLICATION LOGIN ENCRYPTED PASSWORD '$REPLICATION_PASSWORD';
   END IF;
END
\$\$;"

echo "Setting up monitoring extensions on master..."
docker exec -u postgres $MASTER_CONTAINER psql -U postgres -c "
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
CREATE EXTENSION IF NOT EXISTS pg_buffercache;
"

echo "Stopping PostgreSQL inside replica..."
docker exec -u postgres $REPLICA_CONTAINER pg_ctl -D /var/lib/postgresql/data stop 2>/dev/null || true

echo "Cleaning replica data directory..."
docker exec -u postgres $REPLICA_CONTAINER bash -c "rm -rf /var/lib/postgresql/data/*"

echo "Running base backup from master (with password) and fixing permissions..."
docker exec -u postgres $REPLICA_CONTAINER bash -c "
export PGPASSWORD='$REPLICATION_PASSWORD'
pg_basebackup -h $MASTER_CONTAINER -D /var/lib/postgresql/data -U $REPLICATION_USER -P -R
chown -R postgres:postgres /var/lib/postgresql/data
chmod 700 /var/lib/postgresql/data
"

echo "Starting replica..."
docker exec -u postgres $REPLICA_CONTAINER pg_ctl -D /var/lib/postgresql/data start

echo "Waiting for replica to be ready..."
until docker exec -u postgres $REPLICA_CONTAINER pg_isready -U postgres > /dev/null 2>&1; do
    sleep 2
done

echo "Checking replication status..."
docker exec -u postgres $REPLICA_CONTAINER psql -U postgres -c "SELECT pg_is_in_recovery();"

echo "Setting up monitoring user and permissions on master..."
docker exec -u postgres $MASTER_CONTAINER psql -U postgres -c "
DO \$\$ 
BEGIN
   IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'monitoring_user') THEN
      CREATE ROLE monitoring_user WITH LOGIN PASSWORD 'monitoring_pass';
   END IF;
END
\$\$;

GRANT pg_monitor TO monitoring_user;
GRANT SELECT ON pg_stat_database TO monitoring_user;
"

echo "Displaying monitoring configuration on master..."
docker exec -u postgres $MASTER_CONTAINER psql -U postgres -c "
SELECT name, setting FROM pg_settings WHERE name LIKE '%pg_stat_statements%' OR name LIKE '%track%';
"

echo "Testing pg_stat_statements on master..."
docker exec -u postgres $MASTER_CONTAINER psql -U postgres -d sport_center -c "
SELECT 
    query,
    calls,
    total_exec_time,
    mean_exec_time
FROM pg_stat_statements 
ORDER BY mean_exec_time DESC 
LIMIT 5;
"

echo "Replication and monitoring setup completed successfully!"
echo ""
echo "Access points:"
echo "Master PostgreSQL: localhost:5440"
echo "Replica PostgreSQL: localhost:5441" 
echo "Postgres Exporter metrics: localhost:9187/metrics"
echo "Prometheus: localhost:9090"
echo "Grafana: localhost:3000 (admin/admin)"
echo ""
echo "To test monitoring: curl http://localhost:9187/metrics | grep postgres_up"
echo "To test replication: docker exec -it pg_sub psql -U postgres -c 'SELECT pg_is_in_recovery();'"
echo "To analyze queries: docker exec -it pg_main psql -U postgres -d sport_center -c 'SELECT query, mean_exec_time FROM pg_stat_statements ORDER BY mean_exec_time DESC LIMIT 10;'"