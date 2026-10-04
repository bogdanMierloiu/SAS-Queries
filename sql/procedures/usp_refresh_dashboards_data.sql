-- PROCEDURE: sas_visual_analytics.usp_refresh_dashboards_data()

-- DROP PROCEDURE IF EXISTS sas_visual_analytics.usp_refresh_dashboards_data();

CREATE OR REPLACE PROCEDURE sas_visual_analytics.usp_refresh_dashboards_data(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_cnt BIGINT;
BEGIN

    -- Orchestrator: porneste secvential cele 5 proceduri.
    -- Fiecare procedura sas_N isi scrie singura auditul in
    -- sas_visual_analytics.execution_traces si isi face propriul COMMIT,
    -- de aceea orchestratorul NU are bloc EXCEPTION: un handler ar deschide o
    -- subtranzactie si ar bloca COMMIT-ul din procedurile apelate
    -- ("cannot commit while a subtransaction is active").

    -- 1) rezultate_frauda_publish (baza de clienti: NLC-urile din *_aplicare_result)
    CALL sas_visual_analytics.sas_1_usp_refresh_rezultate_frauda_publish();
    SELECT COUNT(*) INTO v_cnt FROM sas_visual_analytics.rezultate_frauda_publish;
    RAISE NOTICE 'rezultate_frauda_publish: % rows', v_cnt;

    -- 2) consum_silver
    CALL sas_visual_analytics.sas_2_usp_refresh_consum_silver();
    SELECT COUNT(*) INTO v_cnt FROM sas_visual_analytics.consum_silver;
    RAISE NOTICE 'consum_silver: % rows', v_cnt;

    -- 3) informatii_de_business_publish
    CALL sas_visual_analytics.sas_3_usp_refresh_informatii_de_business_publish();
    SELECT COUNT(*) INTO v_cnt FROM sas_visual_analytics.informatii_de_business_publish;
    RAISE NOTICE 'informatii_de_business_publish: % rows', v_cnt;

    -- 4) informatii_tehnice_publish
    CALL sas_visual_analytics.sas_4_usp_refresh_informatii_tehnice_publish();
    SELECT COUNT(*) INTO v_cnt FROM sas_visual_analytics.informatii_tehnice_publish;
    RAISE NOTICE 'informatii_tehnice_publish: % rows', v_cnt;

    -- 5) informatii_verificare_publish
    CALL sas_visual_analytics.sas_5_usp_refresh_informatii_verificare_publish();
    SELECT COUNT(*) INTO v_cnt FROM sas_visual_analytics.informatii_verificare_publish;
    RAISE NOTICE 'informatii_verificare_publish: % rows', v_cnt;

END;
$BODY$;
ALTER PROCEDURE sas_visual_analytics.usp_refresh_dashboards_data()
    OWNER TO pgadmin;
