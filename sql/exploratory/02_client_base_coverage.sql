-- =====================================================================
-- 02 - CLIENT BASE COVERAGE (FUNNEL)
-- =====================================================================

-- Funnel: din baza de clienti, cati ajung in fiecare tabela
WITH base AS (SELECT DISTINCT punct_de_consum FROM sas_visual_analytics.v_aplicare_result_base)
SELECT
  (SELECT COUNT(*) FROM base)                                                                        AS baza_nlc,
  (SELECT COUNT(DISTINCT punct_de_consum) FROM sas_visual_analytics.rezultate_frauda_publish)        AS in_rezultate,
  (SELECT COUNT(DISTINCT punct_de_consum) FROM sas_visual_analytics.informatii_de_business_publish)  AS in_business,
  (SELECT COUNT(DISTINCT punct_de_consum) FROM sas_visual_analytics.informatii_tehnice_publish)      AS in_tehnice,
  (SELECT COUNT(DISTINCT punct_de_consum) FROM sas_visual_analytics.consum_silver)                   AS in_consum,
  (SELECT COUNT(DISTINCT punct_de_consum) FROM sas_visual_analytics.informatii_verificare_publish)   AS in_verificare;

-- NLC-uri din baza care NU au ajuns in rezultate_frauda
-- (cauze posibile: fara factura in fereastra, fara lc/contor/sparte 01-02)
SELECT COUNT(*) AS baza_fara_rezultate
FROM sas_visual_analytics.v_aplicare_result_base b
LEFT JOIN sas_visual_analytics.rezultate_frauda_publish r ON r.punct_de_consum = b.punct_de_consum
WHERE r.punct_de_consum IS NULL;

-- exemple de NLC pierdute (cele cu probabilitate mare = prioritate la investigatie)
SELECT b.punct_de_consum, b.prob_1
FROM sas_visual_analytics.v_aplicare_result_base b
LEFT JOIN sas_visual_analytics.rezultate_frauda_publish r ON r.punct_de_consum = b.punct_de_consum
WHERE r.punct_de_consum IS NULL
ORDER BY b.prob_1 DESC NULLS LAST
LIMIT 50;

-- puncte in rezultate dar FARA consum (nicio citire valida in fereastra)
SELECT COUNT(DISTINCT r.punct_de_consum) AS rezultate_fara_consum
FROM sas_visual_analytics.rezultate_frauda_publish r
LEFT JOIN sas_visual_analytics.consum_silver c ON c.punct_de_consum = r.punct_de_consum
WHERE c.punct_de_consum IS NULL;

-- puncte in rezultate dar FARA informatii_tehnice (fara instalatie/contor activ)
SELECT COUNT(DISTINCT r.punct_de_consum) AS rezultate_fara_tehnice
FROM sas_visual_analytics.rezultate_frauda_publish r
LEFT JOIN sas_visual_analytics.informatii_tehnice_publish t ON t.punct_de_consum = r.punct_de_consum
WHERE t.punct_de_consum IS NULL;
