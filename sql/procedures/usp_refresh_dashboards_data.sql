-- PROCEDURE: sas_visual_analytics.usp_refresh_dashboards_data()

-- DROP PROCEDURE IF EXISTS sas_visual_analytics.usp_refresh_dashboards_data();

CREATE OR REPLACE PROCEDURE sas_visual_analytics.usp_refresh_dashboards_data(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_cnt BIGINT;
	v_start_dttm timestamptz := date_trunc('second', clock_timestamp());
BEGIN

    -- usp_refresh_rezultate_frauda_publish;

    INSERT INTO sas_visual_analytics.execution_traces
        ("JOB", "START_DTTM", "END_DTTM","ID_DTTM")
    VALUES
        ('usp_refresh_rezultate_frauda_publish', clock_timestamp(), NULL, v_start_dttm);

    CALL sas_visual_analytics.sas_1_usp_refresh_rezultate_frauda_publish();

    SELECT COUNT(*) INTO v_cnt
    FROM sas_visual_analytics.rezultate_frauda_publish;

    RAISE NOTICE 'rezultate_frauda_publish: % rows', v_cnt;

    UPDATE sas_visual_analytics.execution_traces
    SET "END_DTTM" = clock_timestamp()
    WHERE "JOB"='usp_refresh_rezultate_frauda_publish' and "ID_DTTM" = v_start_dttm;

    -- usp_refresh_consum_silver;

    INSERT INTO sas_visual_analytics.execution_traces
        ("JOB", "START_DTTM", "END_DTTM","ID_DTTM")
    VALUES
        ('usp_refresh_consum_silver', clock_timestamp(), NULL, v_start_dttm);

    CALL sas_visual_analytics.sas_2_usp_refresh_consum_silver();

    SELECT COUNT(*) INTO v_cnt
    FROM sas_visual_analytics.consum_silver;

    RAISE NOTICE 'consum_silver: % rows', v_cnt;

    UPDATE sas_visual_analytics.execution_traces
    SET "END_DTTM" = clock_timestamp()
    WHERE "JOB"='usp_refresh_consum_silver' and "ID_DTTM" = v_start_dttm;

    -- usp_refresh_informatii_de_business_publish;

    INSERT INTO sas_visual_analytics.execution_traces
        ("JOB", "START_DTTM", "END_DTTM","ID_DTTM")
    VALUES
        ('usp_refresh_informatii_de_business_publish', clock_timestamp(), NULL, v_start_dttm);

    CALL sas_visual_analytics.sas_3_usp_refresh_informatii_de_business_publish();

    SELECT COUNT(*) INTO v_cnt
    FROM sas_visual_analytics.informatii_de_business_publish;

    RAISE NOTICE 'informatii_de_business_publish: % rows', v_cnt;

    UPDATE sas_visual_analytics.execution_traces
    SET "END_DTTM" = clock_timestamp()
    WHERE "JOB"='usp_refresh_informatii_de_business_publish' and "ID_DTTM" = v_start_dttm;

    -- usp_refresh_informatii_tehnice_publish;

    INSERT INTO sas_visual_analytics.execution_traces
        ("JOB", "START_DTTM", "END_DTTM","ID_DTTM")
    VALUES
        ('usp_refresh_informatii_tehnice_publish', clock_timestamp(), NULL, v_start_dttm);

    CALL sas_visual_analytics.sas_4_usp_refresh_informatii_tehnice_publish();

    SELECT COUNT(*) INTO v_cnt
    FROM sas_visual_analytics.informatii_tehnice_publish;

    RAISE NOTICE 'informatii_tehnice_publish: % rows', v_cnt;

    UPDATE sas_visual_analytics.execution_traces
    SET "END_DTTM" = clock_timestamp()
    WHERE "JOB"='usp_refresh_informatii_tehnice_publish' and "ID_DTTM" = v_start_dttm;

    -- usp_refresh_informatii_verificare_publish;

    INSERT INTO sas_visual_analytics.execution_traces
        ("JOB", "START_DTTM", "END_DTTM","ID_DTTM")
    VALUES
        ('usp_refresh_informatii_verificare_publish', clock_timestamp(), NULL, v_start_dttm);

    CALL sas_visual_analytics.sas_5_usp_refresh_informatii_verificare_publish();

    SELECT COUNT(*) INTO v_cnt
    FROM sas_visual_analytics.informatii_verificare_publish;

    RAISE NOTICE 'informatii_verificare_publish: % rows', v_cnt;

    UPDATE sas_visual_analytics.execution_traces
    SET "END_DTTM" = clock_timestamp()
    WHERE "JOB"='usp_refresh_informatii_verificare_publish' and "ID_DTTM" = v_start_dttm;

EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END;
$BODY$;
ALTER PROCEDURE sas_visual_analytics.usp_refresh_dashboards_data()
    OWNER TO pgadmin;
