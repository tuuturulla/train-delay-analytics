"""
Haetaan Fintrafficin -rajapinnasta päiväkohtainen junadata paikalliseen
staging-kansioon. Skripti hakee endpointista /trains/<YYYY-MM-DD> yhden päivän kaikki junat
ja kirjoittaa vastauksen tiedostoon:

    data/lake/staging/junajumis/date=<päivä>/trains_raw.json
"""

import requests
import datetime
import argparse
import time
from pathlib import Path

SAFE_INTERVAL_S = 1.25      # ~48 req/min, API:n raja 60 rew/min. 
REQ_TIMEOUT = 20 #sekunteina 
HOST = "https://rata.digitraffic.fi/api/v1"
HEADERS = {'Digitraffic-User': 'Jumittaako/JunaJumis 1.0'} #API:n pyytämä header

def parse_args():
    """
    Parsii komentoriviargumentit.

    Palauttaa:
        argparse.Namespace: Olio, jossa seuraavat kentät:
            - start_date (str): Alkupäivä muodossa YYYY-MM-DD (pakollinen).
            - end_date (str|None): Loppupäivä muodossa YYYY-MM-DD (oletus: eilinen).
            - dry_run (bool): Jos True, ei kirjoita tiedostoja—tulostaa vain mitä tehtäisiin.
    """
    args = argparse.ArgumentParser()
    args.add_argument("--start_date", "-s", type=str, required=True)
    args.add_argument("--end_date", type=str, default=None)
    args.add_argument("--dry-run", action="store_true")
    args = args.parse_args()
    return args

def generate_dates(start_date:str, end_date:str|None) -> tuple[datetime.date, datetime.date]:
    """
    Muodostaa päivämäärävälin.

    Args:
        start_date (str): Alkupäivä muodossa YYYY-MM-DD.
        end_date (str|None): Loppupäivä muodossa YYYY-MM-DD. Jos None, käytetään eilistä.

    Returns:
        tuple[datetime.date, datetime.date]: (start_dt, end_dt), joilla voi iteroida päivä päivältä.

    Huom:
        Loppupäivän oletus ”eilinen” estää hakemasta keskeneräistä kuluvaa päivää.
    """
    start_dt = datetime.date.fromisoformat(start_date)

    if end_date is None:
        end_dt = datetime.date.today() - datetime.timedelta(days=1)
    else:
        end_dt = datetime.date.fromisoformat(end_date)

    return start_dt, end_dt

def create_directories() -> Path:
    """
    Luo (tarvittaessa) staging-hakemiston juuren projektiin.

    Rakennetta ei muuteta—staging sijaitsee polussa:
        <projektijuuri>/data/lake/staging/junajumis

    Returns:
        pathlib.Path: STAGING_ROOT -hakemiston polku.
    """
    PROJECT_DIR = Path(__file__).absolute().parent.parent.parent
    STAGING_ROOT = PROJECT_DIR / "data" / "lake" / "staging" / "junajumis"
    STAGING_ROOT.mkdir(parents=True, exist_ok=True)
    return STAGING_ROOT


def setup_date_generator(start_date:datetime.date, end_date:datetime.date):
    """
    Generoi listan päivämääristä suljettuna välinä [start_date, end_date].

    Args:
        start_date (datetime.date): Alku.
        end_date (datetime.date): Loppu (mukana).

    Returns:
        list[datetime.date]: Päivät järjestyksessä vanhimmasta uusimpaan.
    """
    n_days_gen = range((end_date - start_date).days + 1)
    return [start_date + datetime.timedelta(days=i) for i in n_days_gen]

if __name__ == "__main__":
    #Pääohjelma: käy kaikki päivät läpi, luodaan 1 GET per päivä ja kirjoitetaan raakadata tiedostoon. 
    args = parse_args()
    STAGING_ROOT = create_directories()
    start_date, end_date = generate_dates(args.start_date, args.end_date)
    list_of_dates = setup_date_generator(start_date, end_date)

    print(f"[INFO] Fetching data from {start_date} to {end_date} ({len(list_of_dates)} day(s))")

    for day in list_of_dates:
        day_dir = STAGING_ROOT / f"date={day.isoformat()}"
        day_dir.mkdir(parents=True, exist_ok=True)

        url = f"{HOST}/trains/{day.isoformat()}"
        output_path = day_dir / "trains_raw.json"

        if output_path.exists():
            print(f"[SKIP] {day} already exists -> {output_path}")
            time.sleep(SAFE_INTERVAL_S)
            continue

        if args.dry_run:
            print(f"[SIMULATION] GET {url} -> {output_path}")
            time.sleep(SAFE_INTERVAL_S)
            continue

        try:
            r = requests.get(url, headers=HEADERS, timeout=REQ_TIMEOUT)
            r.raise_for_status()
        except Exception as e:
            print(f"[ERROR] {day} fetch failed: {e}")
            time.sleep(SAFE_INTERVAL_S)
            continue

        output_path.write_bytes(r.content)
        print(f"[OK] {day} -> {output_path}")

        time.sleep(SAFE_INTERVAL_S)
