-- Insert the data by properly parsing the JSON response
INSERT INTO health.residents (id, name, age, city, conditions)
WITH generated_data AS (
  SELECT ml_generate_text_result['candidates'][0]['content'] as raw_content
  FROM ML.GENERATE_TEXT(
    MODEL `wz-data-catalog-demo.health.llm`,
    (
      SELECT 'Generate synthetic public health data for residents of Wisconsin in JSON array format, including id, name, age, city, and conditions for 10 residents.' AS prompt
    ),
    STRUCT(
      0.2 AS temperature,
      1024 AS max_output_tokens
    )
  )
),
extracted_json AS (
  SELECT JSON_VALUE(raw_content, '$.parts[0].text') as json_text
  FROM generated_data
),
parsed_data AS (
  SELECT PARSE_JSON(
    TRIM(
      TRIM(json_text, '```json\n'),
      '```\n'
    )
  ) as data
  FROM extracted_json
),
unnested_data AS (
  SELECT 
    JSON_VALUE(resident, '$.id') as id,
    JSON_VALUE(resident, '$.name') as name,
    CAST(JSON_VALUE(resident, '$.age') AS INT64) as age,
    JSON_VALUE(resident, '$.city') as city,
    (SELECT STRING_AGG(JSON_VALUE(condition), ', ')
     FROM UNNEST(JSON_EXTRACT_ARRAY(resident, '$.conditions')) as condition
    ) as conditions
  FROM parsed_data,
  UNNEST(JSON_EXTRACT_ARRAY(data)) as resident
)
SELECT * FROM unnested_data;