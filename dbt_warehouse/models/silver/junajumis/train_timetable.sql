WITH unnested AS(
  SELECT 
    sk_train,
    trainNumber as train_number,
    departureDate as departure_date,
    -- operatorUICCode,
    -- operatorShortCode,
    trainType as train_type,
    trainCategory as train_category,
    -- commuterLineID,
    -- runningCurrently,
    cancelled,
    deleted,
    -- version,
    -- timetableType,
    -- timetableAcceptanceDate,
    unnest(timeTableRows) as timetable_row
  FROM {{ref('junajumis_api')}}
  ), 

  defined AS (
    SELECT 
      * EXCLUDE (timetable_row),
    
      json_extract_string(timetable_row, '$.stationShortCode') as station_short_code,
      json_extract(timetable_row, '$.stationUICCode')::INT as station_uic_code,
      json_extract_string(timetable_row, '$.type') as event_type, 
      json_extract(timetable_row, '$.trainStopping')::BOOLEAN as train_stopping,
      json_extract(timetable_row, '$.commercialStop')::BOOLEAN as commercial_stop,
      json_extract(timetable_row, '$.cancelled')::BOOLEAN as stop_cancelled,
      json_extract(timetable_row, '$.scheduledTime')::TIMESTAMP as scheduled_time,
      json_extract(timetable_row, '$.actualTime')::TIMESTAMP as actual_time,
      json_extract(timetable_row, '$.differenceInMinutes')::INT as difference_in_minutes
    
    FROM unnested 
  )

SELECT
    {{ dbt_utils.generate_surrogate_key([
      'sk_train', 'station_short_code', 'event_type', 'scheduled_time'
    ]) }} AS sk_train_timetable,
    * EXCLUDE (sk_train)
FROM defined
