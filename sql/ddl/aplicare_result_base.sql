-- View: sas_visual_analytics.v_aplicare_result_base
--
-- Baza de clienti (NLC) pentru popularea tuturor tabelelor de dashboard.
-- Inlocuieste fosta tabela integration.probabilitate.
--
-- Rezultatele modelului de frauda sunt livrate lunar in tabelele
-- integration.<energie>_<tip_client>_aplicare_result, toate cu aceeasi structura
-- (vezi integration.gn_pf_aplicare_result). Deocamdata este populata doar
-- integration.gn_pf_aplicare_result; celelalte trei sunt pregatite, dar inca nu
-- sunt gata, asa ca liniile lor de UNION ALL raman comentate pana cand apar datele.
--
-- Expune doar ce ne trebuie in aval: NLC-ul (ca punct_de_consum bigint) si prob_1.

-- DROP VIEW IF EXISTS sas_visual_analytics.v_aplicare_result_base;

CREATE OR REPLACE VIEW sas_visual_analytics.v_aplicare_result_base AS
WITH aplicare_result_union AS (
    SELECT nlc, prob_1 FROM integration.gn_pf_aplicare_result
    -- UNION ALL
    -- SELECT nlc, prob_1 FROM integration.gn_pj_aplicare_result
    -- UNION ALL
    -- SELECT nlc, prob_1 FROM integration.ee_pf_aplicare_result
    -- UNION ALL
    -- SELECT nlc, prob_1 FROM integration.ee_pj_aplicare_result
)
SELECT DISTINCT ON (btrim(a.nlc))
    btrim(a.nlc)         AS nlc,             -- text, pentru join direct pe punct_de_consum (text)
    btrim(a.nlc)::bigint AS punct_de_consum, -- bigint, pentru filtrele IN (...)
    a.prob_1
FROM aplicare_result_union a
WHERE a.nlc IS NOT NULL
  AND btrim(a.nlc) ~ '^[0-9]+$'
ORDER BY btrim(a.nlc), a.prob_1 DESC NULLS LAST;

ALTER VIEW IF EXISTS sas_visual_analytics.v_aplicare_result_base
    OWNER TO pgadmin;
