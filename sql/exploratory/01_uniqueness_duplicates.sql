-- =====================================================================
-- 01 - UNIQUENESS / DUPLICATES
-- =====================================================================

-- rezultate_frauda_publish NU are PK -> cate puncte au duplicate si cate randuri in plus
SELECT COUNT(*) AS puncte_duplicate,
       COALESCE(SUM(n - 1), 0) AS randuri_in_plus
FROM (
    SELECT punct_de_consum, COUNT(*) AS n
    FROM sas_visual_analytics.rezultate_frauda_publish
    GROUP BY punct_de_consum
    HAVING COUNT(*) > 1
) d;

-- exemple de puncte duplicate in rezultate_frauda_publish
SELECT punct_de_consum, COUNT(*) AS n
FROM sas_visual_analytics.rezultate_frauda_publish
GROUP BY punct_de_consum
HAVING COUNT(*) > 1
ORDER BY n DESC
LIMIT 50;

-- informatii_de_business_publish are PK pe punct_de_consum -> trebuie 0 randuri
SELECT punct_de_consum, COUNT(*) AS n
FROM sas_visual_analytics.informatii_de_business_publish
GROUP BY punct_de_consum
HAVING COUNT(*) > 1;

-- informatii_tehnice_publish (DISTINCT ON punct_de_consum) -> trebuie 0 randuri
SELECT punct_de_consum, COUNT(*) AS n
FROM sas_visual_analytics.informatii_tehnice_publish
GROUP BY punct_de_consum
HAVING COUNT(*) > 1;

-- consum_silver: cheia naturala (equnr, zwnummer, kennziff, data_citire) -> dubluri?
SELECT equnr, zwnummer, kennziff, data_citire, COUNT(*) AS n
FROM sas_visual_analytics.consum_silver
GROUP BY equnr, zwnummer, kennziff, data_citire
HAVING COUNT(*) > 1
ORDER BY n DESC
LIMIT 50;

-- baza de clienti: view-ul face DISTINCT ON (nlc) -> trebuie 0 duplicate
SELECT punct_de_consum, COUNT(*) AS n
FROM sas_visual_analytics.v_aplicare_result_base
GROUP BY punct_de_consum
HAVING COUNT(*) > 1;
