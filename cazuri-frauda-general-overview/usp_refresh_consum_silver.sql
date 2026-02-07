CREATE OR REPLACE PROCEDURE sas_visual_analytics.usp_refresh_consum_silver()
LANGUAGE plpgsql
AS $$
BEGIN
    BEGIN


-- CONTOR --
TRUNCATE TABLE sas_visual_analytics.contor_clean;

INSERT INTO sas_visual_analytics.contor_clean (
    devloc, equnr, sparte, complexitate_instalatie, datab_d, datbi_d
)
SELECT DISTINCT ON (c.devloc)
    c.devloc,
    c.equnr,
    c.sparte,
    CASE
        WHEN UPPER(c.matnr_desc) LIKE '%MONO%' THEN 1
        WHEN UPPER(c.matnr_desc) LIKE '%TRI%'  THEN 3
        ELSE 1
    END AS complexitate_instalatie,
    TO_DATE(c.datab::text, 'YYYYMMDD') AS datab_d,
    TO_DATE(c.datbi::text, 'YYYYMMDD') AS datbi_d
FROM integration.contor c
WHERE c.devloc IS NOT NULL
  AND c.datab IS NOT NULL
  AND c.datbi IS NOT NULL
  AND c.gertyptxtl = 'contor'
  AND CURRENT_DATE BETWEEN TO_DATE(c.datab::text, 'YYYYMMDD')
                        AND TO_DATE(c.datbi::text, 'YYYYMMDD')
ORDER BY c.devloc,
         CASE
            WHEN UPPER(c.matnr_desc) LIKE '%MONO%' THEN 1
            WHEN UPPER(c.matnr_desc) LIKE '%TRI%'  THEN 3
            ELSE 1
         END DESC;


-- TRANSFORMATOR --
TRUNCATE TABLE sas_visual_analytics.transformator_clean;

INSERT INTO sas_visual_analytics.transformator_clean (devloc, complexitate_instalatie)
WITH base AS (
    SELECT
        t.devloc,
        t.wgruppe,
        substring(t.wgruppe from '^[^0-9]*') AS tip,
        regexp_replace(t.wgruppe, '[^0-9/]', '', 'g') AS numere_doar
    FROM integration.transformator t
    WHERE t.gertyptxtl = 'transformat'
	  AND t.devloc IS NOT NULL
      AND t.wgruppe IS NOT NULL
      AND t.wgruppe LIKE '%/%'
),
vals AS (
    SELECT
        b.devloc,
        b.wgruppe,
        b.tip,
        b.numere_doar,
        NULLIF(split_part(b.numere_doar, '/', 1), '')::numeric AS val_primar,
        CASE
            WHEN split_part(b.numere_doar, '/', 2) IN ('', '0', '00') THEN NULL
            WHEN split_part(b.numere_doar, '/', 2) ~ '^0[0-9]+'
                THEN ('0.' || substring(split_part(b.numere_doar, '/', 2) FROM 2))::numeric
            ELSE split_part(b.numere_doar, '/', 2)::numeric
        END AS val_secundar
    FROM base b
),
rt AS (
    SELECT
        v.devloc,
        v.wgruppe,
        CASE
            WHEN v.val_secundar IS NOT NULL AND v.val_secundar <> 0
                THEN v.val_primar / v.val_secundar
        END AS raport_transformare
    FROM vals v
),
distinct_rt AS (SELECT DISTINCT devloc, wgruppe, raport_transformare from rt)
SELECT devloc,
	   CAST(3 * SUM(raport_transformare) AS INT) AS complexitate_instalatie
  FROM distinct_rt
 GROUP BY devloc;


-- COMPLEXITATE INSTALATIE --
TRUNCATE TABLE sas_visual_analytics.complexitate_instalatie;

INSERT INTO sas_visual_analytics.complexitate_instalatie (
    devloc, complexitate_instalatie, sursa_complexitate
)
SELECT devloc,
	   complexitate_instalatie AS complexitate_instalatie,
	   'CONTOR' AS sursa_complexitate
 FROM sas_visual_analytics.contor_clean
WHERE complexitate_instalatie IS NOT NULL

UNION ALL

SELECT devloc,
	   complexitate_instalatie AS complexitate_instalatie,
	  'TRANSFORMATOR' AS sursa_complexitate
FROM sas_visual_analytics.transformator_clean
WHERE complexitate_instalatie IS NOT NULL;


-- REZULTATE FRAUDA --
TRUNCATE TABLE sas_visual_analytics.tmp_bill_39;

WITH params AS (
    SELECT
        (current_date - interval '3 years')::date AS start_date,
        current_date::date AS end_date
),
ee_last AS (
    SELECT DISTINCT ON (b.punct_de_consum)
        b.punct_de_consum,
        b.localitate,
        CASE WHEN b.judet = 'VR' THEN 'VN' ELSE b.judet END AS judet,
        b.subregiune,
        b.clasa_contract,
        b.partener_de_afaceri_descriere
    FROM integration.bill39_ee b
    CROSS JOIN params p
    WHERE b.punct_de_consum IS NOT NULL
      AND sas_visual_analytics.immutable_to_date(b.data_facturare, 'DD.MM.YYYY') >= p.start_date
      AND sas_visual_analytics.immutable_to_date(b.data_facturare, 'DD.MM.YYYY') <= p.end_date
    ORDER BY
        b.punct_de_consum,
        sas_visual_analytics.immutable_to_date(b.data_facturare, 'DD.MM.YYYY') DESC,
        b.numar_factura DESC
),
gn_last AS (
    SELECT DISTINCT ON (b.punct_de_consum)
        b.punct_de_consum,
        b.localitate,
        CASE WHEN b.judet = 'VR' THEN 'VN' ELSE b.judet END AS judet,
        b.subregiune,
        b.clasa_contract,
        b.partener_de_afaceri_descriere
    FROM integration.bill39_gn b
    CROSS JOIN params p
    WHERE b.punct_de_consum IS NOT NULL
      AND sas_visual_analytics.immutable_to_date(b.data_facturare, 'DD.MM.YYYY') >= p.start_date
      AND sas_visual_analytics.immutable_to_date(b.data_facturare, 'DD.MM.YYYY') <= p.end_date
    ORDER BY
        b.punct_de_consum,
        sas_visual_analytics.immutable_to_date(b.data_facturare, 'DD.MM.YYYY') DESC,
        b.numar_factura DESC
),
combined AS (
    SELECT * FROM ee_last
    UNION ALL
    SELECT * FROM gn_last
)
INSERT INTO sas_visual_analytics.tmp_bill_39 (
    punct_de_consum,
    localitate,
    judet,
    subregiune,
    clasa_contract,
    partener_de_afaceri_descriere
)
SELECT DISTINCT ON (punct_de_consum)
    punct_de_consum,
    localitate,
    judet,
    subregiune,
    clasa_contract,
    partener_de_afaceri_descriere
FROM combined
ORDER BY punct_de_consum;

TRUNCATE TABLE sas_visual_analytics.tmp_ci_clean;

INSERT INTO sas_visual_analytics.tmp_ci_clean (devloc, sursa_complexitate, complexitate_instalatie)
SELECT
    ci.devloc,
    ci.sursa_complexitate,
    ci.complexitate_instalatie
FROM sas_visual_analytics.complexitate_instalatie ci
INNER JOIN (SELECT devloc,
			       MAX(complexitate_instalatie) AS complexitate_instalatie
			FROM sas_visual_analytics.complexitate_instalatie
			GROUP BY devloc
			) ci_max ON ci.devloc = ci_max.devloc
			        AND ci.complexitate_instalatie = ci_max.complexitate_instalatie;

TRUNCATE TABLE sas_visual_analytics.rezultate_frauda_publish;

INSERT INTO sas_visual_analytics.rezultate_frauda_publish
SELECT
    p.probabilitate_de_frauda,
    b.localitate,
    b.judet,
    b.punct_de_consum::text AS punct_de_consum_str,
    CAST(b.punct_de_consum AS BIGINT) AS punct_de_consum,
    b.clasa_contract,
    b.partener_de_afaceri_descriere,

    CASE
        WHEN cnt.sparte = '01' THEN ci.complexitate_instalatie
        WHEN cnt.sparte = '02' THEN 1
    END AS complexitate_instalatie,

    CASE
      WHEN abs(trim(lc.gps_lat)::numeric) <= 90
      THEN NULLIF(trim(lc.gps_lat)::numeric, 0)::decimal(10,6)
      ELSE NULL
    END AS gps_lat,
    CASE
      WHEN abs(trim(lc.gps_lon)::numeric) <= 180
      THEN NULLIF(trim(lc.gps_lon)::numeric, 0)::decimal(10,6)
      ELSE NULL
    END AS gps_lon,

    CASE
            WHEN cnt.sparte = '01' THEN 'Electricitate'
            WHEN cnt.sparte = '02' THEN 'Gaz'
            ELSE 'N/A'
        END AS tip_energie,
    CASE
            WHEN cnt.sparte = '01' THEN 1
            WHEN cnt.sparte = '02' THEN 2
            ELSE 3
        END AS tip_energie_measure,
    ci.sursa_complexitate
FROM sas_visual_analytics.tmp_bill_39 b
INNER JOIN integration.lc lc ON b.punct_de_consum = lc.vstelle
INNER JOIN integration.probabilitate p ON b.punct_de_consum = p.nlc
INNER JOIN sas_visual_analytics.contor_clean cnt ON lc.devloc = cnt.devloc
                                                        AND cnt.sparte IN ('01', '02')
INNER JOIN sas_visual_analytics.tmp_ci_clean ci ON ci.devloc = lc.devloc;

    EXCEPTION
        WHEN OTHERS THEN
            RAISE;
    END;
END;
$$;
