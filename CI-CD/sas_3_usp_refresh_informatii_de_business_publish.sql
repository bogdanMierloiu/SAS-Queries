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
        ('sas_4_usp_refresh_informatii_tehnice_publish', clock_timestamp(), NULL, v_start_dttm, v_numar_linii);

COMMIT;

-- cod

    TRUNCATE TABLE sas_visual_analytics.tehnic_contor_clean;

    INSERT INTO sas_visual_analytics.tehnic_contor_clean (
        devloc,
        equnr,
        sparte,
        matnr,
        matnr_desc,
        sernr,
        gertyptxtl,
        ami_am_active,
        datab_date,
        datbi_date
    )
    SELECT DISTINCT ON (c.devloc)
        c.devloc,
        c.equnr,
        c.sparte,
        c.matnr,
        c.matnr_desc,
        c.sernr,
        c.gertyptxtl,
        c.ami_am_active,
        TO_DATE(c.datab::text, 'YYYYMMDD') AS datab_date,
        TO_DATE(c.datbi::text, 'YYYYMMDD') AS datbi_date
    FROM integration.contor c
    WHERE c.devloc IS NOT NULL
      AND c.datab IS NOT NULL
      AND c.datbi IS NOT NULL
      AND CURRENT_DATE BETWEEN TO_DATE(c.datab::text, 'YYYYMMDD')
                           AND TO_DATE(c.datbi::text, 'YYYYMMDD')
    ORDER BY
        c.devloc,
        TO_DATE(c.datab::text, 'YYYYMMDD') DESC,
        TO_DATE(c.datbi::text, 'YYYYMMDD') DESC;

COMMIT;


    TRUNCATE TABLE sas_visual_analytics.informatii_tehnice_publish;

    INSERT INTO sas_visual_analytics.informatii_tehnice_publish (
        punct_de_consum,
        punct_de_consum_str,

        adresa,
        gps_latitudine,
        gps_longitudine,

        loc_dispozitiv,

        tip_punct_consum_desc,

        nr_persoane,

        instalatie,
        divizie,
        divizie_desc,
        categorie_tarif,
        categorie_tarif_desc,
        grila_cod,
        grid_name,
        nivel_retea,
		loading_dttm
    )
    SELECT DISTINCT ON (b.punct_de_consum)
        b.punct_de_consum,
        b.punct_de_consum::text AS punct_de_consum_str,

        lc.address AS adresa,
        lc.gps_lat AS gps_latitudine,
        lc.gps_lon AS gps_longitudine,

        lc.devloc AS loc_dispozitiv,

        lc.vbsart_desc AS tip_punct_consum_desc,

        lc.anzpers::INT AS nr_persoane,

        inst.anlage        AS instalatie,
        inst.sparte        AS divizie,
        inst.sparte_desc   AS divizie_desc,
        inst.tariftyp      AS categorie_tarif,
        inst.tariftyp_desc AS categorie_tarif_desc,
        inst.grid_id       AS grila_cod,
        inst.grid_name     AS grid_name,
        inst.grid_level    AS nivel_retea,
        LOCALTIMESTAMP AS loading_dttm

    FROM sas_visual_analytics.business_bill_39 b
    INNER JOIN integration.lc lc
            ON b.punct_de_consum_str = lc.vstelle
    INNER JOIN integration.instalatie inst
            ON b.numar_instalatie = inst.anlage
    INNER JOIN sas_visual_analytics.tehnic_contor_clean cnt
            ON cnt.devloc = lc.devloc
    ORDER BY
        b.punct_de_consum,
        lc.devloc DESC;
COMMIT;

-- update traces

    SELECT COUNT(*) INTO v_cnt
    FROM sas_visual_analytics.informatii_tehnice_publish;

    RAISE NOTICE 'informatii_tehnice_publish: % rows', v_cnt;

    UPDATE sas_visual_analytics.execution_traces
    SET "END_DTTM" = clock_timestamp()
    WHERE "JOB"='sas_4_usp_refresh_informatii_tehnice_publish' and "ID_EXECUTIE" = v_numar_linii;

COMMIT;

-- EXCEPTION
--     WHEN OTHERS THEN
--         RAISE;
END;

