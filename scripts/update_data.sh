#!/bin/bash

set -e

# Check that the first argument exists. If not, print usage:
if [ -z "$1" ]; then
    echo "Usage: $0 <start-date-YYYY-MM-DD> [<end-date-YYYY-MM-DD>]"
    exit 1
fi

# Run ingestor script
uv run python src/ingestor/junajumis.py \
  --start_date $1 \
  --end_date ${2:-}

# Run the dbt commands
echo "[STEP] Running dbt models"
cd dbt_warehouse
uv run dbt run
uv run dbt docs generate
cd ..

# # Copy the duckdb database file to Evidence's sources directory
echo "[STEP] Copy DuckDB to Evidence sources dir"
SOURCE_FILE=data/warehouse/warehouse.duckdb
DEST_FILE=bi/workspace/sources/warehouse/warehouse.duckdb
mkdir -p bi/workspace/sources/warehouse/
cp $SOURCE_FILE $DEST_FILE

echo "[DONE] Data updated & Evidence warehouse.duckdb refreshed."