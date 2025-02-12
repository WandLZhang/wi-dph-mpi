WITH
  resolution_1 AS (
  SELECT
    *
  FROM
    VECTOR_SEARCH ( TABLE health.pdfs_embed,
      'ml_generate_embedding_result',
      TABLE health.vaccinations_embed,
      top_k => 1 ) )
SELECT
  resolution_2.query.content AS vaccination_table,
  resolution_1.base.content AS pdf_table,
  resolution_1.distance AS distance_2,
  resolution_2.base.content AS resident_table,
  resolution_2.distance AS distance_1
FROM
  VECTOR_SEARCH ( TABLE health.residents_embed,
    'ml_generate_embedding_result',
    TABLE health.vaccinations_embed,
    top_k => 5 ) AS resolution_2
JOIN
  resolution_1
ON
  resolution_2.query.content = resolution_1.query.content