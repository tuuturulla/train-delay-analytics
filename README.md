# JunaJumis
*"Asemat, joissa aikataulu käy kahvilla"*  

Projektin tavoitteena on kartoittaa, **mille asemille junat keskimäärin saapuvat eniten myöhässä** ja **mihin vuorokaudenaikoihin myöhästymiset kasautuvat** lokakuussa 2025 Fintrafficin junadataa hyödyntäen.  

## 0. Onko lippu ja lupa? – Vaatimukset

Tarvitset:

-  Python **3.11**
- [uv](https://docs.astral.sh/uv/) (riippuvuuksien hallinta) 
- Git  
- Paikallinen DuckDB (CLI)  
- Docker + Docker Compose (Evidence-deville)

---

## 1. Ensiasennus uudella koneella – Ratapihan pystytys 🚧

Nämä tehdään **kerran / kone** (tai kun riippuvuudet muuttuvat).

### 1.1 Kloonaus & projektiin sisään

```bash
git clone git@gitlab.dclabra.fi:data-alustat-2025/sarapyky.git
cd sarapyky
```

### 1.2 Python-riippuvuudet kuntoon (uv)

```bash
uv sync
```
Jos `uv` puuttuu: `pip install uv` tai asenna virallisten ohjeiden mukaan.

Tämä asentaa kaikki pyproject.toml:issa määritellyt Python-depsit (mukaan lukien dbt & dbt-duckdb).

### 1.3 dbt-projekti kuntoon
```bash
uv run dbt deps
uv run dbt debug
```
Saat ``All checks passed!`` kun dbt löytää profiilin ja DuckDB-varasto (data/warehouse/warehouse.duckdb) on ok. Tarkista ``profiles.yml`` ja polut, koska juna ei lähde asemalta ilman rataverkkoa. 

### 1.4 Evidence-ensikäynnistys – Volyymit & kansiot
Alkutoimet, jotta Evidence-volume ja bi/workspace syntyvät oikein:
```bash
docker compose -f docker-compose.init.yml up --build
docker compose -f docker-compose.init.yml down
```

## 2. Päivittäinen ajelu – Data yhdellä komennolla 🚂
Kun yllä olevat ensiasennukset on suoritettu, datan päivitys onnistuu näppärästi yhdellä komennolla.

```bash
# Esimerkki 1: Haetaan datat 1.10.2025 → eiliseen asti
bash scripts/update_data.sh YYYY-MM-DD

# Esimerkki 2: Haetaan tarkka aikaväli 1.10.–31.10.2025
bash scripts/update_data.sh YYYY-MM-DD YYYY-MM-DD
```

Skripti suorittaa peräkkäin:
1. Hakee junadatan Fintrafficin API:sta 
2. Ajaa dbt-mallit DuckDB:hen
3. Kopioi DuckDB-tietokannan Evidenceä varten 

> Lyhyesti: update_data.sh = “Päivitä data, aja mallit ja tarjoile Evidenceen”.
Kuljettajalle yksi nappi, ratapihalle monta vaihdetta 🚦

## 3. Jos haluat ajaa vaiheet käsin – Pitkä matka yöjunalla 🌙
Jos et halua nopeinta junaa minkä update_data.sh tarjoaa vaan koko setin niin alla on pidempi versio. 

### 3.1 Raakadatan haku (Bronze / lake) 
Ingestori: src/ingestor/junajumis.py

```bash
# Step 1: Kuiva ajo halutusta päivästä eiliseen asti (ei kirjoita levylle)
uv run python src/ingestor/junajumis.py -s YYYY-MM-DD --dry-run

# E.g 1: Hae halutusta päivästä (eiliseen asti)
uv run python src/ingestor/junajumis.py -s YYYY-MM-DD

# E.g 2: Hae tarkka aikaväli 
uv run python src/ingestor/junajumis.py -s YYYY-MM-DD --end_date YYYY-MM-DD
```
**Tallennuspolku**: data/lake/staging/junajumis/date=YYYY-MM-DD/trains_raw.json

Jokaiselle päivälle löytyy oma hakemistonsa (date=...), jossa on Digitrafficin raakavastaus.

### 3.2 dbt-ajot (Bronze → Silver → Gold) 
Aja kaikki mallit:
```bash
uv run dbt run
```
Tai kerros kerrallaan:
```bash
# Bronze-kerros: raakadatasta strukturoiduksi
uv run dbt run --select bronze

# Silver-kerros: faktoja ja dimensioita
uv run dbt run --select silver

# Gold-kerros: liiketoimintavalmiit mittarit & näkymät
uv run dbt run --select gold
```

### 3.3 DuckDB UI 
```bash
duckdb -ui data/warehouse/warehouse.duckdb
```
Pystyt tarkastelemaan dbt:n generoimia tauluja ja voit suorittaa SQL-kyselyitä käsin. 

### dbt Docs 
```bash
# Luo dokumentaatio
uv run dbt docs generate

# Palvele dokumentaatiota lokaalisti
uv run dbt docs serve
```
Avaa selaimessa dbt:n UI:n (skeemat, kuvaukset jne). Pystyt tarkistelemaan miten taulut liittyvät toisiinsa.

## 4. Mallinnuskerrokset – Veturi, vaunut & asemat 🛠️
**"Vetää kuin junan vessa"**: Bronze → Silver → Gold 
- Bronze: raakajunadata JSON -> taulukoksi
- Silver (fakta- ja dimensiotasot):
    - **train_timetable** (SK: sk_train_timetable)
    - **f_arrivals** (validit saapumiset, avain = sk_arrival = sk_train_timetable)
    - **f_trainislate** (myöhässä olevat saapumiset, minutes_late > 0, avain: sk_islate)
    - **d_station** (asema-dimensio: station_short_code, station_uic_code)
- Gold:
    - **bottleneck_stations** (Mille asemille junat keskimäärin saapuvat eniten myöhässä: late_rate, p90_minutes_late, severity_score) 
    - **rush_hours_stations** (Asemakohtaiset tuntitasoiset saapumiset ja myöhästymiset lokakuussa 2025)
    - Nämä taulut ovat Evidence-dashboardin tietolähteitä.

## 5. Evidence – Kuljettajan näkymä ohjaamossa 👩‍✈️
Evidence lukee DuckDB-tietokannan ja visualisoi gold-tason taulut. 

### 5.1 Build & käynnistys
Ensimmäisellä kerralla / Dockerfileä muutettaessa:
```bash
docker compose build
```
Käynnistä dev-palvelu + live-reload:
```bash
docker compose up --watch
```
Evidence palvelee selaimessa osoitteessa ```http://localhost:3000```

### 6. Yhteenveto – Miten juna pidetään kartalla 🎯
Uusi kone / uusi kehittäjä?
➡️ Katso kohta 1.

Haluat vain tuoreen datan & päivitetyn raportin?
➡️ Aja:
```bash
bash scripts/update_data.sh YYYY-MM-DD YYYY-MM-DD
docker compose up --watch   # jos ei jo päällä
```

Haluat näprätä yksittäistä kerrosta tai debugata?
➡️ Käytä kohtia 3–5.

Ja jos juna on myöhässä – ainakin data on ajoissa 😉