WITH arrivals AS (
  SELECT
    sk_train_timetable              AS sk_arrival,   
    train_number,
    departure_date,
    station_short_code,
    station_uic_code,
    scheduled_time,
    CAST(scheduled_time AS DATE) AS service_date
  FROM {{ ref('train_timetable') }}
  WHERE event_type = 'ARRIVAL'
    AND actual_time IS NOT NULL
    AND COALESCE(stop_cancelled, FALSE) = FALSE
    AND COALESCE(cancelled, FALSE)      = FALSE
    AND COALESCE(deleted, FALSE)        = FALSE
)
SELECT * FROM arrivals