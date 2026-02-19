CREATE OR REPLACE PROCEDURE sas_visual_analytics.usp_refresh_dashboards_data()
LANGUAGE plpgsql
AS $$
DECLARE
    v_cnt BIGINT;
BEGIN
    CALL sas_visual_analytics.usp_refresh_rezultate_frauda_publish();

    SELECT COUNT(*) INTO v_cnt
    FROM sas_visual_analytics.rezultate_frauda_publish;

    RAISE NOTICE 'rezultate_frauda_publish: % rows', v_cnt;

    CALL sas_visual_analytics.usp_refresh_consum_silver();

    SELECT COUNT(*) INTO v_cnt
    FROM sas_visual_analytics.consum_silver;

    RAISE NOTICE 'consum_silver: % rows', v_cnt;

    CALL sas_visual_analytics.usp_refresh_informatii_de_business_publish();

    SELECT COUNT(*) INTO v_cnt
    FROM sas_visual_analytics.informatii_de_business_publish;

    RAISE NOTICE 'informatii_de_business_publish: % rows', v_cnt;

    CALL sas_visual_analytics.usp_refresh_informatii_tehnice_publish();

    SELECT COUNT(*) INTO v_cnt
    FROM sas_visual_analytics.informatii_tehnice_publish;

    RAISE NOTICE 'informatii_tehnice_publish: % rows', v_cnt;

    CALL sas_visual_analytics.usp_refresh_informatii_verificare_publish();

    SELECT COUNT(*) INTO v_cnt
    FROM sas_visual_analytics.informatii_verificare_publish;

    RAISE NOTICE 'informatii_verificare_publish: % rows', v_cnt;

EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END;
$$;
