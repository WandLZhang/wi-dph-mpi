-- Compare embeddings from pdfs_embed against residents_embed
WITH pdf_data AS (
  SELECT DISTINCT content, ml_generate_embedding_result
  FROM `wz-data-catalog-demo.health.pdfs_embed`
),
matches AS (
  SELECT 
    source.content as pdf_content,
    residents.content as resident_name,
    residents.distance as similarity_score,
    ROW_NUMBER() OVER (PARTITION BY source.content ORDER BY residents.distance ASC) as rank
  FROM pdf_data source,
  VECTOR_SEARCH(
    table `wz-data-catalog-demo.health.residents_embed`,
    'ml_generate_embedding_result',
    (SELECT ml_generate_embedding_result 
     FROM `wz-data-catalog-demo.health.pdfs_embed` 
     LIMIT 1)
  ) residents
)
SELECT 
  pdf_content,
  resident_name,
  similarity_score
FROM matches
WHERE rank <= 2
ORDER BY pdf_content, similarity_score ASC
