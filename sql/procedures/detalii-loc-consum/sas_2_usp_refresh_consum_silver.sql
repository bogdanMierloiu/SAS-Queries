-- PROCEDURE: sas_visual_analytics.sas_2_usp_refresh_consum_silver()

-- DROP PROCEDURE IF EXISTS sas_visual_analytics.sas_2_usp_refresh_consum_silver();

CREATE OR REPLACE PROCEDURE sas_visual_analytics.sas_2_usp_refresh_consum_silver(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_cnt BIGINT;
	v_start_dttm timestamptz := date_trunc('second', clock_timestamp());
	v_numar_linii BIGINT;

BEGIN

-- insert traces
    SELECT COUNT(*) + 1
    INTO v_numar_linii
    FROM sas_visual_analytics.execution_traces;

    RAISE NOTICE 'Valoarea este: %', v_numar_linii;

    INSERT INTO sas_visual_analytics.execution_traces
        ("JOB", "START_DTTM", "END_DTTM","ID_DTTM","ID_EXECUTIE")
    VALUES
        ('sas_2_usp_refresh_consum_silver', clock_timestamp(), NULL, v_start_dttm,v_numar_linii);

COMMIT;

    -- 1) RAW_FILTERED_DATA
    TRUNCATE TABLE sas_visual_analytics.raw_filtered_data;

    INSERT INTO sas_visual_analytics.raw_filtered_data (
        equnr,
        sernr,
        zwnummer,
        data_citire,
        index_val,
        kennziff,
        massread,
        punct_de_consum_str,
        punct_de_consum,
        datab_d,
        datbi_d
    )
    SELECT DISTINCT ON (c.equnr, c.zwnummer, c.data_citire)
        c.equnr,
        c.sernr,
        c.zwnummer,
        c.data_citire,
        c.v_zwstand::numeric AS index_val,
        COALESCE(NULLIF(TRIM(cr.kennziff), ''), 'gaz') AS kennziff,
        cr.massread,
        lc.vstelle::text   AS punct_de_consum_str,
        lc.vstelle::bigint AS punct_de_consum,
        cnt.datab          AS datab_d,
        cnt.datbi          AS datbi_d
    FROM (
        SELECT
            *,
            TO_DATE(adat::text, 'YYYYMMDD') AS data_citire
        FROM integration.citire
    ) c
    INNER JOIN (
        SELECT DISTINCT ON (equnr, zwnummer)
            equnr,
            zwnummer,
            COALESCE(NULLIF(TRIM(kennziff), ''), 'gaz') AS kennziff,
            massread
        FROM integration.contor_registri
        ORDER BY equnr, zwnummer
    ) cr
        ON c.equnr = cr.equnr
       AND c.zwnummer = cr.zwnummer
    INNER JOIN (
        SELECT
            devloc,
            sernr,
            equnr,
            TO_DATE(datab::text, 'YYYYMMDD') AS datab,
            TO_DATE(datbi::text, 'YYYYMMDD') AS datbi
        FROM integration.contor
        WHERE CURRENT_DATE BETWEEN TO_DATE(datab::text, 'YYYYMMDD')
                              AND TO_DATE(datbi::text, 'YYYYMMDD')
          AND devloc IS NOT NULL
          AND datab IS NOT NULL
          AND datbi IS NOT NULL
    ) cnt
        ON cnt.equnr = cr.equnr
    INNER JOIN integration.lc lc
        ON lc.devloc = cnt.devloc
    WHERE c.v_zwstand IS NOT NULL
      AND c.v_zwstand::numeric > 0
      AND c.adat IS NOT NULL
      AND c.adat <> '00000000'
      AND c.data_citire BETWEEN DATE '2024-06-01' AND CURRENT_DATE
      AND lc.vstelle IS NOT NULL
      -- doar clientii din baza *_aplicare_result (NLC-urile scoase de model)
      AND lc.vstelle::bigint IN (
          SELECT punct_de_consum FROM sas_visual_analytics.v_aplicare_result_base
      )
    ORDER BY
        c.equnr,
        c.zwnummer,
        c.data_citire,
        c.data_citire DESC;

COMMIT;

    -- 2) CONSUM_CALCULAT
    TRUNCATE TABLE sas_visual_analytics.consum_calculat;

    INSERT INTO sas_visual_analytics.consum_calculat (
        equnr,
        sernr,
        zwnummer,
        kennziff,
        punct_de_consum,
        punct_de_consum_str,
        data_citire,
        index_val,
        datab_d,
        datbi_d,
        massread,
        consum
    )
    SELECT
        equnr,
        sernr,
        zwnummer,
        kennziff,
        punct_de_consum,
        punct_de_consum_str,
        data_citire,
        index_val,
        datab_d,
        datbi_d,
        massread,
        index_val - LAG(index_val) OVER (
            PARTITION BY equnr, zwnummer, kennziff
            ORDER BY data_citire
        ) AS consum
    FROM sas_visual_analytics.raw_filtered_data
    WHERE data_citire IS NOT NULL
      AND index_val > 0;

COMMIT;

    -- 3) CONSUM_SILVER
    TRUNCATE TABLE sas_visual_analytics.consum_silver;

    INSERT INTO sas_visual_analytics.consum_silver (
        equnr,
        sernr,
        zwnummer,
        kennziff,
        punct_de_consum,
        punct_de_consum_str,
        data_citire,
        index,
        consum,
        massread,
		loading_dttm
    )
    SELECT
        equnr,
        sernr,
        zwnummer,
        kennziff,
        punct_de_consum,
        punct_de_consum_str,
        data_citire,
        index_val AS index,
        ROUND(consum, 2) AS consum,
        massread,
	    LOCALTIMESTAMP AS loading_dttm

    FROM sas_visual_analytics.consum_calculat
    WHERE consum IS NOT NULL
      AND consum > 0
    ORDER BY data_citire DESC, kennziff, zwnummer;

COMMIT;

-- update traces

    SELECT COUNT(*) INTO v_cnt
    FROM sas_visual_analytics.consum_silver;

    RAISE NOTICE 'consum_silver: % rows', v_cnt;

    UPDATE sas_visual_analytics.execution_traces
    SET "END_DTTM" = clock_timestamp()
    WHERE "JOB"='sas_2_usp_refresh_consum_silver' and "ID_EXECUTIE" = v_numar_linii;

COMMIT;

-- EXCEPTION
--     WHEN OTHERS THEN
--         RAISE;
END;

$BODY$;
ALTER PROCEDURE sas_visual_analytics.sas_2_usp_refresh_consum_silver()
    OWNER TO pgadmin;
