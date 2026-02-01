-- rezultate_frauda_publish --

SELECT * FROM sas_visual_analytics.rezultate_frauda_publish WHERE punct_de_consum = 5001656721

-- verify if any column is NULL
SELECT *
FROM sas_visual_analytics.rezultate_frauda_publish
WHERE to_jsonb(rezultate_frauda_publish) ?| ARRAY[''] IS NULL;

SELECT COUNT(*) FROM sas_visual_analytics.rezultate_frauda_publish
--1.571.318

SELECT
    punct_de_consum,
    COUNT(*) AS rn
FROM sas_visual_analytics.rezultate_frauda_publish
GROUP BY punct_de_consum
HAVING COUNT(*) > 1;


-- consum_silver --
SELECT * FROM sas_visual_analytics.consum_silver WHERE punct_de_consum = 5001656721
SELECT COUNT(*) FROM sas_visual_analytics.consum_silver
-- 61.971.339

SELECT
    punct_de_consum,
	equnr, sernr,zwnummer,data_citire,
    COUNT(*) AS rn
FROM sas_visual_analytics.consum_silver
GROUP BY punct_de_consum, equnr, sernr,zwnummer,data_citire
HAVING COUNT(*) > 1;


-- informatii_de_business_publish --
SELECT * FROM sas_visual_analytics.informatii_de_business_publish where punct_de_consum = 5001656721
SELECT COUNT(*) FROM sas_visual_analytics.informatii_de_business_publish
-- 1.575.428

SELECT
    punct_de_consum,
    COUNT(*) AS rn
FROM sas_visual_analytics.informatii_de_business_publish
GROUP BY punct_de_consum
HAVING COUNT(*) > 1;


-- informatii_tehnice_publish --
SELECT * FROM sas_visual_analytics.informatii_tehnice_publish where punct_de_consum = 5001656721
SELECT COUNT(*) FROM sas_visual_analytics.informatii_tehnice_publish
-- 1.511.168


SELECT
    punct_de_consum,
    COUNT(*) AS rn
FROM sas_visual_analytics.informatii_tehnice_publish
GROUP BY punct_de_consum
HAVING COUNT(*) > 1;
