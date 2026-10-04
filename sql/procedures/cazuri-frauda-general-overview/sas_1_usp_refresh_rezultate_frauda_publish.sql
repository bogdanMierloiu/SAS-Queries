-- PROCEDURE: sas_visual_analytics.sas_1_usp_refresh_rezultate_frauda_publish()

-- DROP PROCEDURE IF EXISTS sas_visual_analytics.sas_1_usp_refresh_rezultate_frauda_publish();

CREATE OR REPLACE PROCEDURE sas_visual_analytics.sas_1_usp_refresh_rezultate_frauda_publish(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_cnt BIGINT;
	v_start_dttm timestamptz := date_trunc('second', clock_timestamp());
	v_numar_linii BIGINT;
BEGIN
    BEGIN

-- insert into traces;
    SELECT COUNT(*) + 1
    INTO v_numar_linii
    FROM sas_visual_analytics.execution_traces;

    RAISE NOTICE 'Valoarea este: %', v_numar_linii;

    INSERT INTO sas_visual_analytics.execution_traces
        ("JOB", "START_DTTM", "END_DTTM","ID_DTTM","ID_EXECUTIE")
    VALUES
        ('sas_1_usp_refresh_rezultate_frauda_publish', clock_timestamp(), NULL, v_start_dttm,v_numar_linii);

    -- COMMIT;

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
        (current_date - interval '6 months')::date AS start_date,
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
    p.prob_1 AS probabilitate_de_frauda,
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
        WHEN trim(lc.gps_lat) ~ '^[+-]?[0-9]+(\.[0-9]+)?$'
             AND abs(trim(lc.gps_lat)::double precision) <= 90
        THEN NULLIF(trim(lc.gps_lat)::double precision, 0)
        ELSE NULL
    END AS gps_lat,

    CASE
        WHEN trim(lc.gps_lon) ~ '^[+-]?[0-9]+(\.[0-9]+)?$'
             AND abs(trim(lc.gps_lon)::double precision) <= 180
        THEN NULLIF(trim(lc.gps_lon)::double precision, 0)
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
    ci.sursa_complexitate,
    EXISTS (
        SELECT 1
        FROM integration.field_inspections fi
        WHERE fi.nlc = b.punct_de_consum
    ) AS verificat,
	LOCALTIMESTAMP AS loading_dttm

FROM sas_visual_analytics.tmp_bill_39 b
INNER JOIN integration.lc lc ON b.punct_de_consum = lc.vstelle
-- Baza de clienti (NLC + prob_1) vine din tabelele *_aplicare_result (vezi view-ul).
-- Inlocuieste fosta tabela integration.probabilitate.
INNER JOIN sas_visual_analytics.v_aplicare_result_base p ON btrim(b.punct_de_consum) = p.nlc
INNER JOIN sas_visual_analytics.contor_clean cnt ON lc.devloc = cnt.devloc
                                                        AND cnt.sparte IN ('01', '02')
INNER JOIN sas_visual_analytics.tmp_ci_clean ci ON ci.devloc = lc.devloc;

-- COMMIT;

-- update traces

    SELECT COUNT(*) INTO v_cnt
    FROM sas_visual_analytics.rezultate_frauda_publish;

    RAISE NOTICE 'rezultate_frauda_publish: % rows', v_cnt;

    UPDATE sas_visual_analytics.execution_traces
    SET "END_DTTM" = clock_timestamp()
    WHERE "JOB"='sas_1_usp_refresh_rezultate_frauda_publish' and "ID_EXECUTIE" = v_numar_linii;

    -- COMMIT;

    -- EXCEPTION
    --     WHEN OTHERS THEN
    --         RAISE;
    END;
END;
$BODY$;
ALTER PROCEDURE sas_visual_analytics.sas_1_usp_refresh_rezultate_frauda_publish()
    OWNER TO pgadmin;
