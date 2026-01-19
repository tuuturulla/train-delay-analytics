---
title: Asemakohtaiset ruuhkatunnit
---

```stations
SELECT station_short_code FROM rush_hours_stations
```

```rush_hours
select
  station_short_code,
  hour,
  lpad(hour::varchar, 2, '0') || ':00' as hour_label,
  arrivals,
  late_rate
from rush_hours_stations
where station_short_code = '${inputs.selected_station.value}'
order by hour;
```

## Valitse tarkasteltava asema

<Dropdown
  data={stations}
  name=selected_station
  value=station_short_code
  title="Valitse asema"
  defaultValue=HKI
/>

----

<Heatmap
  data={rush_hours}
  x=hour_label
  y=station_short_code
  value=arrivals
  title={"Asemakohtaiset ruuhkatunnit – " + inputs.selected_station.value}
/>

💡 Näin luet kuvaa: Mitä tummempi ruutu, sitä enemmän junia saapuu kyseisen tunnin aikana – eli ruudut
kertovat aseman ruuhkatunnit. Viemällä hiiren päälle näet saapumisajan ja saapumisten määrät.

---- 


<BarChart 
    data={rush_hours}
    x=hour_label
    y=arrivals
    swapXY=true
	  yAxisTitle="Saapumiset"
    title={"Saapumiset tunneittain – " + inputs.selected_station.value}
/>

💡 Pylväät näyttävät, kuinka monta junaa saapuu kunkin tunnin aikana valitulle asemalle.
Piikit kertovat aseman tärkeimmät ruuhka-ajat.

-----


<BarChart 
  data={rush_hours}
  x=hour_label
  y=arrivals
  y2=late_rate
  y2Fmt=percent1
  y2SeriesType=line
  yAxisTitle="Saapumiset"
  y2AxisTitle="Myöhässä %"
  sort=false
  title={"Saapumiset ja myöhässä saapuvien osuus tunneittain (thr 5 min) – " + inputs.selected_station.value}
 />


💡 Palkit näyttävät saapumisten määrän tunneittain ja viiva näyttää, kuinka suuri
osa saapumisista on vähintään 5 minuuttia myöhässä. Yhdessä nämä kertovat, milloin
asemalla on paljon liikennettä ja samalla korkea myöhästymisriski