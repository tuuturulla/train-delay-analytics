WITH params AS (
  SELECT 
    {{ var('late_threshold_minutes', 5) }}::INT  AS thr,        -- myöhässä-kynnys minuutteina
    {{ var('min_arrivals', 1000) }}::INT         AS min_arrs,   -- minimisaapumiset asemalle
),

arrivals AS (  
  SELECT station_short_code, COUNT(*) AS total_arrivals
  FROM {{ ref('f_arrivals') }}
  GROUP BY 1
),

late AS (
  SELECT station_short_code, minutes_late
  FROM {{ ref('f_trainislate') }}
  WHERE minutes_late >= (SELECT thr FROM params)
),

late_agg AS (
  SELECT
    station_short_code,
    COUNT(*)                         AS late_events,
    quantile_cont(minutes_late,0.9)  AS p90_minutes_late
  FROM late
  GROUP BY station_short_code
), 

scored AS (
  SELECT
    a.station_short_code,
    s.station_uic_code, 
    a.total_arrivals,
    COALESCE(l.late_events, 0)        AS late_events,
    CASE 
      WHEN a.total_arrivals > 0 THEN COALESCE(l.late_events, 0)::DOUBLE / a.total_arrivals
      ELSE 0
    END                                AS late_rate,
    COALESCE(l.p90_minutes_late, 0)    AS p90_minutes_late,
    -- päämittari: "kuinka usein" * "kuinka pahasti" (p90)
    (CASE 
      WHEN a.total_arrivals > 0 THEN COALESCE(l.late_events, 0)::DOUBLE / a.total_arrivals
      ELSE 0
     END) * COALESCE(l.p90_minutes_late, 0)     AS severity_score
  FROM arrivals a
  LEFT JOIN late_agg l USING (station_short_code)
  LEFT JOIN {{ ref('d_station') }} s USING (station_short_code)
  WHERE a.total_arrivals >= (SELECT min_arrs FROM params)
) 

SELECT
  station_short_code,
  total_arrivals,
  late_events,
  late_rate,
  p90_minutes_late,
  severity_score
FROM scored
ORDER BY severity_score DESC, late_rate DESC, p90_minutes_late DESC
LIMIT 10
