-- Rajapinta antaa ajat UTC-aikana. Muunnetaan ne Suomen aikaan ennen tunnin
-- poimimista, jotta ruuhkatunnit vastaavat todellista aikataulua.
-- 'Europe/Helsinki' huomioi myös kesäajan päättymisen 26.10.2025.
with arrivals_local as (
  select a.station_short_code,
         a.sk_arrival,
         (a.scheduled_time at time zone 'UTC') at time zone 'Europe/Helsinki' as scheduled_time_local
  from {{ ref('f_arrivals') }} a
),

hourly as (
  select a.station_short_code,
         extract(hour from a.scheduled_time_local) as hour,
         count(*) as arrivals,
         sum(case when l.minutes_late >= 5 then 1 else 0 end) as late_events
  from arrivals_local a
  left join {{ ref('f_trainislate') }} l using (sk_arrival)
  where a.scheduled_time_local >= date '2025-10-01'
    and a.scheduled_time_local <  date '2025-11-01'
  group by 1,2
)
select station_short_code,
       hour,
       arrivals,
       late_events,
       case when arrivals>0 then late_events::double/arrivals else 0 end as late_rate
from hourly
