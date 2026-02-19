CREATE
OR REPLACE PROCEDURE sas_visual_analytics.usp_refresh_informatii_verificare_publish()
LANGUAGE plpgsql
AS $$
BEGIN
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
                                                                cod_analiza)
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
       fi.cod_analiza
FROM integration.field_inspections fi
WHERE btrim(fi.nlc) ~ '^[0-9]+$'
  AND EXISTS (
      SELECT 1
      FROM sas_visual_analytics.rezultate_frauda_publish r
      WHERE r.punct_de_consum = btrim(fi.nlc)::bigint
  )
ORDER BY TO_DATE(fi.data::text, 'YYYY-MM-DD') DESC;

EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END;
$$;
