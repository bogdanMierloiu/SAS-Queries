-- =====================================================================
-- 03 - REFERENTIAL CONSISTENCY (LEAKAGE)
-- Toate query-urile de mai jos TREBUIE sa returneze 0.
-- Nicio tabela nu trebuie sa contina puncte din afara bazei de clienti.
-- =====================================================================

SELECT COUNT(*) AS rezultate_in_afara_bazei
FROM sas_visual_analytics.rezultate_frauda_publish r
LEFT JOIN sas_visual_analytics.v_aplicare_result_base b ON r.punct_de_consum = b.punct_de_consum
WHERE b.punct_de_consum IS NULL;

SELECT COUNT(*) AS business_in_afara_bazei
FROM sas_visual_analytics.informatii_de_business_publish x
LEFT JOIN sas_visual_analytics.v_aplicare_result_base b ON x.punct_de_consum = b.punct_de_consum
WHERE b.punct_de_consum IS NULL;

SELECT COUNT(*) AS tehnice_in_afara_bazei
FROM sas_visual_analytics.informatii_tehnice_publish x
LEFT JOIN sas_visual_analytics.v_aplicare_result_base b ON x.punct_de_consum = b.punct_de_consum
WHERE b.punct_de_consum IS NULL;

SELECT COUNT(*) AS consum_in_afara_bazei
FROM sas_visual_analytics.consum_silver x
LEFT JOIN sas_visual_analytics.v_aplicare_result_base b ON x.punct_de_consum = b.punct_de_consum
WHERE b.punct_de_consum IS NULL;

SELECT COUNT(*) AS verificare_in_afara_bazei
FROM sas_visual_analytics.informatii_verificare_publish x
LEFT JOIN sas_visual_analytics.v_aplicare_result_base b ON x.punct_de_consum = b.punct_de_consum
WHERE b.punct_de_consum IS NULL;

-- informatii_verificare trebuie sa fie subset din rezultate (sas_5 filtreaza prin EXISTS)
SELECT COUNT(*) AS verificare_fara_rezultate
FROM sas_visual_analytics.informatii_verificare_publish v
LEFT JOIN sas_visual_analytics.rezultate_frauda_publish r ON r.punct_de_consum = v.punct_de_consum
WHERE r.punct_de_consum IS NULL;
