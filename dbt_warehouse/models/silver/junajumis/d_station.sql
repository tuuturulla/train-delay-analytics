SELECT 
  station_short_code,
  station_uic_code
FROM {{ ref('train_timetable') }}
GROUP BY ALL 

