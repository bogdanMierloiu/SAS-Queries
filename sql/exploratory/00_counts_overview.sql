-- =====================================================================
-- 00 - COUNTS OVERVIEW
-- =====================================================================

-- Numar randuri: baza de clienti + toate tabelele finale
SELECT 'v_aplicare_result_base'          AS obiect, COUNT(*) AS n_randuri FROM sas_visual_analytics.v_aplicare_result_base
UNION ALL SELECT 'rezultate_frauda_publish',        COUNT(*) FROM sas_visual_analytics.rezultate_frauda_publish
UNION ALL SELECT 'consum_silver',                    COUNT(*) FROM sas_visual_analytics.consum_silver
UNION ALL SELECT 'informatii_de_business_publish',  COUNT(*) FROM sas_visual_analytics.informatii_de_business_publish
UNION ALL SELECT 'informatii_tehnice_publish',      COUNT(*) FROM sas_visual_analytics.informatii_tehnice_publish
UNION ALL SELECT 'informatii_verificare_publish',   COUNT(*) FROM sas_visual_analytics.informatii_verificare_publish
ORDER BY obiect;

-- Numar NLC-uri distincte (punct_de_consum) pe fiecare tabela
SELECT 'rezultate_frauda_publish'        AS tabela, COUNT(DISTINCT punct_de_consum) AS nlc_distinct FROM sas_visual_analytics.rezultate_frauda_publish
UNION ALL SELECT 'informatii_de_business_publish',  COUNT(DISTINCT punct_de_consum) FROM sas_visual_analytics.informatii_de_business_publish
UNION ALL SELECT 'informatii_tehnice_publish',      COUNT(DISTINCT punct_de_consum) FROM sas_visual_analytics.informatii_tehnice_publish
UNION ALL SELECT 'informatii_verificare_publish',   COUNT(DISTINCT punct_de_consum) FROM sas_visual_analytics.informatii_verificare_publish
UNION ALL SELECT 'consum_silver',                   COUNT(DISTINCT punct_de_consum) FROM sas_visual_analytics.consum_silver
ORDER BY tabela;

-- loading_dttm: toate tabelele ar trebui incarcate in aceeasi rulare
SELECT 'rezultate_frauda_publish'        AS tabela, MIN(loading_dttm) AS min_load, MAX(loading_dttm) AS max_load FROM sas_visual_analytics.rezultate_frauda_publish
UNION ALL SELECT 'consum_silver',                   MIN(loading_dttm), MAX(loading_dttm) FROM sas_visual_analytics.consum_silver
UNION ALL SELECT 'informatii_de_business_publish',  MIN(loading_dttm), MAX(loading_dttm) FROM sas_visual_analytics.informatii_de_business_publish
UNION ALL SELECT 'informatii_tehnice_publish',      MIN(loading_dttm), MAX(loading_dttm) FROM sas_visual_analytics.informatii_tehnice_publish
UNION ALL SELECT 'informatii_verificare_publish',   MIN(loading_dttm), MAX(loading_dttm) FROM sas_visual_analytics.informatii_verificare_publish
ORDER BY tabela;

-- Ultimele rulari din tabela de audit (durata pe job)
SELECT "ID_EXECUTIE", "JOB", "START_DTTM", "END_DTTM",
       ("END_DTTM" - "START_DTTM") AS durata
FROM sas_visual_analytics.execution_traces
ORDER BY "START_DTTM" DESC
LIMIT 20;
