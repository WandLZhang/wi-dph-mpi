-- Simple extraction of vaccination records
WITH text_lines AS (
  SELECT 
    TRIM(line) as line,
    REGEXP_CONTAINS(line, r'^WI-\d+') as is_record_start,
    pos
  FROM ML.PROCESS_DOCUMENT(
    MODEL `health.layout_parser`,
    TABLE `health.pdfs`
  ),
  UNNEST(SPLIT(CAST(JSON_EXTRACT_SCALAR(ml_process_document_result, '$.text') AS STRING), '\n')) as line WITH OFFSET as pos
  WHERE content_type = 'application/pdf'
    AND TRIM(line) != ''
    AND NOT REGEXP_CONTAINS(line, r'^ID|^Name|^Vaccinations|^file:|^\d/\d|^Wisconsin|^\d{1,2}/\d{1,2}/\d{2}')
),
grouped_lines AS (
  SELECT
    line,
    SUM(CASE WHEN is_record_start THEN 1 ELSE 0 END) OVER (ORDER BY pos) as record_group
  FROM text_lines
)

SELECT
  MAX(CASE WHEN REGEXP_CONTAINS(line, r'^WI-\d+')
    THEN REGEXP_EXTRACT(line, r'^(WI-\d+)') END) as id,
  STRING_AGG(
    CASE WHEN NOT REGEXP_CONTAINS(line, r'^WI-\d+') THEN line END,
    '\n'
  ) as notes
FROM grouped_lines
WHERE record_group > 0
GROUP BY record_group
ORDER BY id;
