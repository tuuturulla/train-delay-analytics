WITH arrivals AS (
  SELECT
    sk_train_timetable AS sk_arrival,
    train_number,
    departure_date,
    train_type,
    train_category,
    station_short_code,
    station_uic_code,
    scheduled_time,
    actual_time,
    difference_in_minutes,
    COALESCE(cancelled, FALSE)       AS cancelled,
    COALESCE(deleted, FALSE)         AS deleted,
    COALESCE(stop_cancelled, FALSE)  AS stop_cancelled,
    event_type
  FROM {{ ref('train_timetable') }}
  WHERE event_type = 'ARRIVAL'
    AND actual_time IS NOT NULL
    AND COALESCE(stop_cancelled, FALSE) = FALSE
    AND COALESCE(cancelled, FALSE)      = FALSE
    AND COALESCE(deleted, FALSE)        = FALSE
),

late AS (
  SELECT *
  FROM arrivals
  WHERE difference_in_minutes > 0 -- myöhässä
)

SELECT
  {{ dbt_utils.generate_surrogate_key([
    'train_number','departure_date','station_short_code','scheduled_time'
  ]) }} AS sk_islate,
  sk_arrival,
  station_short_code,
  train_number,
  departure_date,
  scheduled_time,
  difference_in_minutes AS minutes_late,
  TRUE AS is_late
FROM late