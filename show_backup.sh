#!/bin/bash
for f in /var/backups/postgresql/*; do
    size=$(stat -c%s "$f")
    date=$(stat -c'%y' "$f" | cut -d'.' -f1)
    name=$(basename "$f")
    printf "%-40s %-10s %-16s\n" "$name" "$size" "$date"
done
