---
title: Asemakohtaiset myöhästymiset (TOP 10)
---


```top10_bottlenecks
SELECT * from bottleneck_stations
```


<BarChart
  data={top10_bottlenecks}
  x=station_short_code
  y=severity_score
  swapXY=true
  sort=-severity_score
  yFmt=number2
  title="Top 10 asemaa severity-scoren mukaan"
/>

💡 Mitä korkeampi severity_score, sitä "pahempi" asema, joka huomioi sekä myöhässä saapumisten osuuden että viiveen suuruuden.

----

<BubbleChart
  data={top10_bottlenecks}
  x=late_rate
  y=p90_minutes_late
  size=total_arrivals
  tooltipTitle=station_short_code 
  xFmt=percent1
  yFmt=number1
  title="Myöhästymisriski vs viiveen suuruus (pallon koko = saapumiset)"
/>


💡 X-akseli (late_rate) kertoo kuinka usein junat ovat myöhässä.
Y-akseli (p90_minutes_late) kertoo, kuinka pitkä myöhästyminen on tyypillisesti silloin, kun juna on kunnolla myöhässä – eli mitä isompi arvo, sitä pidempi viive.
Pallon koko kuvaa (total_arrivals) liikenteen määrää (suuret asemat = isot pallot). 
Asemat oikeassa yläkulmassa ovat sekä usein, että pahasti myöhässä. 

----

<DataTable 
  data={top10_bottlenecks}
  title="Koko taulukkonäkymä"
  columns="station_short_code,total_arrivals,late_events,late_rate,p90_minutes_late,severity_score"
/>

💡 Taulukosta näet samat tiedot numeerisina ja voit vertailla aseman lukuja tarkemmin.


