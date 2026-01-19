---
title: JunaJumis - junien myöhästymiset lokakuussa 2025
---

---

# JunaJumis 🚆
*Asemat, joissa aikataulu käy kahvilla*

Tämän dashboardin avulla voit tukia, **mille asemille junat saapuvat keskimäärin eniten myöhässä** ja **milloin päivän aikana ruuhkat ja myöhästymiset kasaantuvat**. Tarkastelu perustuu **lokakuun 2025 liikenteeseen**. 

## Mistä näkymistä aloitan? 
- [**Asemakohtaiset myöhästymiset – Top 10**](/top10)  
  Näyttää asemat, joille junat saapuvat suhteellisesti eniten myöhässä
  (severity_scoren perusteella). Sopii "pullonkaulojen" tunnistamiseen ja priorisointiin.

- [**Asemakohtaiset ruuhkatunnit**](/rush_hours)  
  Näyttää valitun aseman saapumiset ja myöhässä saapuvien osuuden tunnin tarkkuudella.
  Sopii aseman “päivärytmin” ja riskituntien tarkasteluun.

> 💡 *Vinkki:* Aloita  Top 10 -näkymästä ja nappaa sieltä kiinnostava asema
> ruuhkatuntisivulle.

---

## Keskeiset käsitteet

**Saapuminen (arrival)**  
: Yksi junan saapuminen aseman aikataulun mukaiseen pysähdykseen.

**Myöhässä (late)**  
: Juna on vähintään **5 minuuttia** myöhässä aikataulusta (minutes_late ≥ 5).

**late_events**  
: Kuinka monta saapumista on myöhässä (thr 5 min).

**arrivals**  
: Saapumisten kokonaismäärä.

**late_rate**  
: Myöhässä saapumisten osuus kaikista saapumisista:  
  `late_events / arrivals` (näytetään prosentteina).

**p90_minutes_late**  
: Myöhästymisen suuruus, jota useimmat (90 %) myöhässä olevista junista **eivät ylitä**.  
  Mitä suurempi p90, sitä pidempiä nämä “pahimmat myöhästymiset” ovat.

**severity_score**  
: Yhdistetty mittari, joka huomioi sekä
  - myöhässä saapumisten osuuden (**late_rate**) että  
  - myöhästymisen suuruuden (**p90_minutes_late**).  
  Mitä suurempi severity_score, sitä “pahempi” asema myöhästymisten kannalta.


