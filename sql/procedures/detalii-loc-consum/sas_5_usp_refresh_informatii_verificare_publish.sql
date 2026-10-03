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
        ('sas_5_usp_refresh_informatii_verificare_publish', clock_timestamp(), NULL, v_start_dttm,v_numar_linii);

COMMIT;

-- code

TRUNCATE TABLE sas_visual_analytics.informatii_verificare_publish;

INSERT INTO sas_visual_analytics.informatii_verificare_publish (punct_de_consum,
                                                                punct_de_consum_str,
                                                                data,
                                                                cod_nec_1,
                                                                stare_loc_consum,
                                                                sursa_input,
                                                                consumator,
                                                                divizie,
                                                                nr_doc_intocmit_pvsd_bmmm,
                                                                nr_nota_de_constatare,
                                                                serie_contor,
                                                                cantitate,
                                                                um,
                                                                cod_analiza,
																loading_dttm)
SELECT btrim(fi.nlc)::bigint AS punct_de_consum, fi.nlc AS punct_de_consum_str,
       TO_DATE(fi.data::text, 'YYYY-MM-DD') AS data,
       fi.cod_nec_1,
       fi.stare_loc_consum,
       fi.sursa_input,
       fi.consumator,
       fi.divizie,
       fi.nr_doc_intocmit_pvsd_bmmm,
       fi.nr_nota_constatare                AS nr_nota_de_constatare,
       fi.serie_contor,
       fi.cantitate,
       fi.um,
       fi.cod_analiza,
       LOCALTIMESTAMP AS loading_dttm

FROM integration.field_inspections fi
WHERE btrim(fi.nlc) ~ '^[0-9]+$'
  AND EXISTS (
      SELECT 1
      FROM sas_visual_analytics.rezultate_frauda_publish r
      WHERE r.punct_de_consum = btrim(fi.nlc)::bigint
  )
ORDER BY TO_DATE(fi.data::text, 'YYYY-MM-DD') DESC;

COMMIT;

-- update traces

    SELECT COUNT(*) INTO v_cnt
    FROM sas_visual_analytics.informatii_verificare_publish;

    RAISE NOTICE 'informatii_verificare_publish: % rows', v_cnt;

    UPDATE sas_visual_analytics.execution_traces
    SET "END_DTTM" = clock_timestamp()
    WHERE "JOB"='sas_5_usp_refresh_informatii_verificare_publish' and "ID_EXECUTIE" = v_numar_linii;

COMMIT;

-- EXCEPTION
--     WHEN OTHERS THEN
--         RAISE;
END;
