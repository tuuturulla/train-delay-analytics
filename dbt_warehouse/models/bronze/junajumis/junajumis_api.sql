WITH trains AS (
  SELECT 
    *
  FROM read_json('..\data\lake\staging\junajumis\*\*.json', 
    columns = {
      'trainNumber':              'INT',
      'departureDate':            'DATE',
      'operatorUICCode':          'INT',
      'operatorShortCode':        'STRING',
      'trainType':                'STRING',
      'trainCategory':            'STRING',
      'commuterLineID':           'STRING',
      'runningCurrently':         'BOOLEAN',
      'cancelled':                'BOOLEAN',
      'deleted':                  'BOOLEAN',
      'version':                  'BIGINT',
      'timetableType':            'STRING',
      'timetableAcceptanceDate':  'TIMESTAMP',
      'timeTableRows':            'JSON[]'
    }
  )
),

surrogate_key_added AS (
  SELECT
    {{ dbt_utils.generate_surrogate_key([
      'trainNumber', 'departureDate'
    ]) }} AS sk_train,
  *
  FROM trains
)

SELECT *
FROM surrogate_key_added