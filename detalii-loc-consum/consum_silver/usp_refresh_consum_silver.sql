CREATE OR REPLACE PROCEDURE sas_visual_analytics.usp_refresh_consum_silver()
LANGUAGE plpgsql
AS $$
BEGIN
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
    ORDER BY
        c.equnr,
        c.zwnummer,
        c.data_citire,
        c.data_citire DESC;

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
        massread
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
        massread
    FROM sas_visual_analytics.consum_calculat
    WHERE consum IS NOT NULL
      AND consum > 0
    ORDER BY data_citire DESC, kennziff, zwnummer;

EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END;
$$;
