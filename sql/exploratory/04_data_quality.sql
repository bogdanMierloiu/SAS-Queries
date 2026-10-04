-- =====================================================================
-- 04 - DATA QUALITY
-- =====================================================================

-- rezultate_frauda_publish: probabilitate valida (asteptat in [0,1]) si fara null
SELECT
  COUNT(*)                                                                            AS total,
  COUNT(*) FILTER (WHERE probabilitate_de_frauda IS NULL)                             AS prob_null,
  COUNT(*) FILTER (WHERE probabilitate_de_frauda < 0 OR probabilitate_de_frauda > 1)  AS prob_out_of_range,
  MIN(probabilitate_de_frauda)                                                        AS prob_min,
  MAX(probabilitate_de_frauda)                                                        AS prob_max,
  ROUND(AVG(probabilitate_de_frauda)::numeric, 4)                                     AS prob_avg
FROM sas_visual_analytics.rezultate_frauda_publish;

-- distributie pe 10 buckete de probabilitate
SELECT width_bucket(probabilitate_de_frauda::double precision, 0, 1, 10) AS bucket_0_10,
       COUNT(*) AS n
FROM sas_visual_analytics.rezultate_frauda_publish
WHERE probabilitate_de_frauda IS NOT NULL
GROUP BY bucket_0_10
ORDER BY bucket_0_10;

-- tip energie
SELECT tip_energie, COUNT(*) AS n
FROM sas_visual_analytics.rezultate_frauda_publish
GROUP BY tip_energie
ORDER BY n DESC;

-- GPS lipsa in rezultate
SELECT COUNT(*) FILTER (WHERE gps_lat IS NULL OR gps_lon IS NULL) AS fara_gps,
       COUNT(*)                                                   AS total
FROM sas_visual_analytics.rezultate_frauda_publish;

-- consum_silver: consum trebuie > 0 (filtrat in procedura) -> verifica
SELECT COUNT(*) FILTER (WHERE consum IS NULL) AS consum_null,
       COUNT(*) FILTER (WHERE consum <= 0)    AS consum_nepozitiv,
       MIN(consum)                            AS min_consum,
       MAX(consum)                            AS max_consum
FROM sas_visual_analytics.consum_silver;

-- consum pe tip (kennziff) + intervalul de date de citire
SELECT kennziff, COUNT(*) AS n, ROUND(AVG(consum)::numeric, 2) AS consum_mediu
FROM sas_visual_analytics.consum_silver
GROUP BY kennziff
ORDER BY n DESC;

SELECT MIN(data_citire) AS prima_citire, MAX(data_citire) AS ultima_citire
FROM sas_visual_analytics.consum_silver;

-- informatii_de_business: completitudine campuri cheie
SELECT
  COUNT(*)                                             AS total,
  COUNT(*) FILTER (WHERE judet IS NULL)                AS fara_judet,
  COUNT(*) FILTER (WHERE partener_de_afaceri IS NULL)  AS fara_partener,
  COUNT(*) FILTER (WHERE name IS NULL)                 AS fara_name
FROM sas_visual_analytics.informatii_de_business_publish;

-- informatii_verificare: cate inspectii per NLC (normal pot fi mai multe)
SELECT COUNT(*)                          AS total_inspectii,
       COUNT(DISTINCT punct_de_consum)   AS nlc_distincte,
       MIN(data)                         AS prima_inspectie,
       MAX(data)                         AS ultima_inspectie
FROM sas_visual_analytics.informatii_verificare_publish;
