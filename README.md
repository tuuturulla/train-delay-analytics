# JunaJumis
*"Stations where the timetable goes for a coffee"* ☕

Goal: map **which stations trains arrive late to the most (on average)** and **when during the day delays pile up**, using Fintraffic train data (October 2025).

> Coursework for the Data Platforms course in ICT engineering studies. The course provided the base project structure; the research question, dbt models, metrics and dashboard are my own.

> **Update (November 2026):** Fixed a time zone bug in the rush hour view. The API returns times in UTC, and hours were originally extracted directly from them, so the view was 2–3 hours behind Finnish time. The `rush_hours_stations` model now converts times to Europe/Helsinki (including the end of summer time) before extracting the hour.

## 0. Ticket & permission check — Requirements

You'll need:

-  Python **3.11**
- [uv](https://docs.astral.sh/uv/) (dependency management) 
- Git  
- DuckDB (CLI)  
- Docker + Docker Compose (for Evidence dev)

---

## 1. First-time setup — building the rail yard 🚧

Do this **once per machine** (or when dependencies change).

### 1.1 Clone & enter the project

```bash
git clone git@github.com:tuuturulla/train-delay-analytics.git
cd train-delay-analytics
```

### 1.2 Install Python deps (uv)

```bash
uv sync
```
if `uv` is missing: `pip install uv` (or install via official docs)

This installs everything from pyproject.toml (including dbt + dbt-duckdb)

### 1.3 dbt setup
```bash
uv run dbt deps
uv run dbt debug
```
You should see ``All checks passed!`` when dbt finds the profile and the DuckDB warehouse (data/warehouse/warehouse.duckdb) is OK. Check ``profiles.yml`` + paths if the train refuses to leave the station. 


### 1.4 Evidence first boot — volumes & folders

Initial setup so Evidence volumes + bi/workspace get created correctly: 
```bash
docker compose -f docker-compose.init.yml up --build
docker compose -f docker-compose.init.yml down
```

## 2. Daily driving — data with one command 🚂

After setup, updating data is basically one button. 

```bash
# Example 1: Fetch from a given date
bash scripts/update_data.sh YYYY-MM-DD

# Example 2: Fetch a specific range (e.g. Oct 1–31, 2025)
bash scripts/update_data.sh YYYY-MM-DD YYYY-MM-DD
```

What the script does, in order:
1. Fetches train data from the Fintraffic API 
2. Runs dbt models and builds DuckDB tables
3. Copies the DuckDB database for Evidence

> In short: update_data.sh = “Update data, run models, and serve it to Evidence”.
One button for the driver, many switches in the rail yard 🚦

## 3. Manual mode — the night train route 🌙
If you don't want the fastest route (update_data.sh), here's the longer version.

### 3.1 Raw data ingest (Bronze / lake)
Ingestor: src/ingestor/junajumis.py

```bash
# Dry run: from start date → until yesterday (no files written)
uv run python src/ingestor/junajumis.py -s YYYY-MM-DD --dry-run

# Example 1: fetch from a start date (until yesterday)
uv run python src/ingestor/junajumis.py -s YYYY-MM-DD

# Example 2: fetch a specific range
uv run python src/ingestor/junajumis.py -s YYYY-MM-DD --end_date YYYY-MM-DD
```
**Output path**: data/lake/staging/junajumis/date=YYYY-MM-DD/trains_raw.json

Each day gets its own folder (date=...) with the raw Digitraffic/Fintraffic response.

### 3.2. dbt runs (Bronze → Silver → Gold)
Run everything:
```bash
uv run dbt run
```
Or layer by layer:
```bash
# Bronze: raw → structured
uv run dbt run --select bronze

# Silver: facts + dimensions
uv run dbt run --select silver

# Gold: business-ready metrics/views
uv run dbt run --select gold
```

### 3.3 DuckDB UI 
```bash
duckdb -ui data/warehouse/warehouse.duckdb
```
You can inspect dbt-generated tables and run SQL manually.

### dbt Docs 
```bash
# Create docs
uv run dbt docs generate

# Serve docs
uv run dbt docs serve
```
Open the dbt docs UI in your browser to see schemas, descriptions, and how tables connect.

## 4. Modeling layers — locomotive, wagons & stations 🛠️
**"Pulls like a train toilet"**: Bronze → Silver → Gold 
- Bronze: raw train JSON → tables
- Silver (facts + dims):
    - **train_timetable** (SK: sk_train_timetable)
    - **f_arrivals** (valid arrivals, key = sk_arrival = sk_train_timetable)
    - **f_trainislate** (late arrivals, minutes_late > 0, key: sk_islate)
    - **d_station** (station dimension: station_short_code, station_uic_code)
- Gold:
    - **bottleneck_stations** (where trains arrive late the most: late_rate, p90_minutes_late, severity_score) 
    - **rush_hours_stations** (hour-level arrivals + delays by station for Oct 2025)

These Gold tables feed the Evidence dashboard.

## 5. Evidence — the driver’s cockpit view 👩‍✈️
Evidence reads the DuckDB warehouse and visualizes Gold-level tables.

### 5.1 Build & run
First time (or when the Dockerfile changes):
```bash
docker compose build
```
Start dev server + live reload:
```bash
docker compose up --watch
```
Evidence runs at: ```http://localhost:3000```

### 6. TL;DR — keeping the train on track 🎯
New machine / new dev?
➡️ See section 1

Just want fresh data + updated dashboard?
➡️ Run:
```bash
bash scripts/update_data.sh YYYY-MM-DD YYYY-MM-DD
docker compose up --watch  # if not already running
```

Want to debug specific layers?
➡️ Use sections 3–5

And if the train is late — at least the data is on time 😉