#!/bin/bash

for i in {1..120}; do
  echo "Итерация $i"
  docker exec pg_main psql -U postgres -d sport_center -f /tmp/test.sql
  sleep 1
done