#!/bin/bash

# Запуск всех CRUD SQL-файлов для спортивного центра

echo "Запуск CRUD.sql"
psql -U postgres -d sport_center -f CRUD.sql

echo "Все CRUD операции выполнены."