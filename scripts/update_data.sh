#!/bin/bash

set -e

# Check that the first argument exists. If not, print usage:
if [ -z "$1" ]; then
    echo "Error: Give a start date at least (e.g. 2024-01-01)"
    echo "Usage: $0 <start-date-YYYY-MM-DD> [<end-date-YYYY-MM-DD>]"
    exit 1
fi

echo "[STEP] Ingested data from Junajumis API for date range: $1 to ${2:-$1}"

# Run ingestor script
uv run python src/ingestor/junajumis.py \
  --start_date $1 \
  --end_date ${2:-$1}


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