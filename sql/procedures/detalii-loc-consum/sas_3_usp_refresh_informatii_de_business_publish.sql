-- PROCEDURE: sas_visual_analytics.sas_3_usp_refresh_informatii_de_business_publish()

-- DROP PROCEDURE IF EXISTS sas_visual_analytics.sas_3_usp_refresh_informatii_de_business_publish();

CREATE OR REPLACE PROCEDURE sas_visual_analytics.sas_3_usp_refresh_informatii_de_business_publish(
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
        ('sas_3_usp_refresh_informatii_de_business_publish', clock_timestamp(), NULL, v_start_dttm, v_numar_linii);

COMMIT;

-- cod

    TRUNCATE TABLE sas_visual_analytics.business_bill_39;

    WITH params AS (
        SELECT (current_date - interval '3 years')::date AS start_date
    ),
    bill39 AS (
        -- EE
        SELECT *
        FROM (
            SELECT DISTINCT ON (b.punct_de_consum)
                'ee' AS tip,
                b.punct_de_consum,
                b.numar_instalatie,
                b.partener_de_afaceri,
                b.clasa_contract,
                b.categorie_tarif,
                b.tip_facturare,
                b.invoicing_party,
                b.nivel_tensiune,
                b.urban_rural,
                CASE WHEN b.judet = 'VR' THEN 'VN' ELSE b.judet END AS judet,
                b.localitate,
                b.strada,
                b.subregiune
            FROM integration.bill39_ee b
            CROSS JOIN params p
            WHERE b.punct_de_consum IS NOT NULL
              AND sas_visual_analytics.immutable_to_date(b.data_facturare, 'DD.MM.YYYY') >= p.start_date
            ORDER BY
                b.punct_de_consum,
                sas_visual_analytics.immutable_to_date(b.data_facturare, 'DD.MM.YYYY') DESC,
                b.numar_factura DESC
        ) ee

        UNION ALL

        -- GN
        SELECT *
        FROM (
            SELECT DISTINCT ON (b.punct_de_consum)
                'gn' AS tip,
                b.punct_de_consum,
                b.numar_instalatie,
                b.partener_de_afaceri,
                b.clasa_contract,
                b.categorie_tarif,
                b.tip_facturare,
                b.invoicing_party,
                b.nivel_tensiune,
                b.urban_rural,
                CASE WHEN b.judet = 'VR' THEN 'VN' ELSE b.judet END AS judet,
                b.localitate,
                b.strada,
                b.subregiune
            FROM integration.bill39_gn b
            CROSS JOIN params p
            WHERE b.punct_de_consum IS NOT NULL
              AND sas_visual_analytics.immutable_to_date(b.data_facturare, 'DD.MM.YYYY') >= p.start_date
            ORDER BY
                b.punct_de_consum,
                sas_visual_analytics.immutable_to_date(b.data_facturare, 'DD.MM.YYYY') DESC,
                b.numar_factura DESC
        ) gn
    )
    INSERT INTO sas_visual_analytics.business_bill_39 (
        punct_de_consum,
        punct_de_consum_str,
        numar_instalatie,

        partener_de_afaceri,

        clasa_contract,
        categorie_tarif,
        tip_facturare,
        invoicing_party,
        nivel_tensiune,
        urban_rural,

        judet,
        localitate,
        strada,
        subregiune
    )
    SELECT DISTINCT ON (a.punct_de_consum)
        a.punct_de_consum::bigint AS punct_de_consum,
        a.punct_de_consum::text   AS punct_de_consum_str,
        a.numar_instalatie,

        a.partener_de_afaceri,

        a.clasa_contract,
        a.categorie_tarif,
        a.tip_facturare,
        a.invoicing_party,
        a.nivel_tensiune,
        a.urban_rural,

        a.judet,
        a.localitate,
        a.strada,
        a.subregiune
    FROM bill39 a
    ORDER BY
        a.punct_de_consum,
        (a.tip = 'ee') DESC; -- prefera EE daca exista in ambele

COMMIT;

    TRUNCATE TABLE sas_visual_analytics.informatii_de_business_publish;

    INSERT INTO sas_visual_analytics.informatii_de_business_publish (
        punct_de_consum,
        punct_de_consum_str,
        numar_instalatie,

        partener_de_afaceri,
        name,
        reg_number,
        cif_number,

        clasa_contract,
        categorie_tarif,
        tip_facturare,
        invoicing_party,
        nivel_tensiune,
        urban_rural,

        judet,
        localitate,
        strada,
        subregiune,

        region,
        region_name,
        city,

        ind_sector,
        ind_sector_desc,

        loading_dttm

    )
    SELECT
        b.punct_de_consum,
        b.punct_de_consum_str,
        b.numar_instalatie,

        b.partener_de_afaceri,
        p.name,
        p.reg_number,
        p.cif_number,

        b.clasa_contract,
        b.categorie_tarif,
        b.tip_facturare,
        b.invoicing_party,
        b.nivel_tensiune,
        b.urban_rural,

        b.judet,
        b.localitate,
        b.strada,
        b.subregiune,

        p.region,
        p.region_name,
        p.city,

        p.ind_sector,
        p.ind_sector_desc,
	    LOCALTIMESTAMP AS loading_dttm

    FROM sas_visual_analytics.business_bill_39 b
    LEFT JOIN integration.partner p
           ON b.partener_de_afaceri = p.partner;

COMMIT;

-- update traces

    SELECT COUNT(*) INTO v_cnt
    FROM sas_visual_analytics.informatii_de_business_publish;

    RAISE NOTICE 'informatii_de_business_publish: % rows', v_cnt;

    UPDATE sas_visual_analytics.execution_traces
    SET "END_DTTM" = clock_timestamp()
    WHERE "JOB"='sas_3_usp_refresh_informatii_de_business_publish' and "ID_EXECUTIE" = v_numar_linii;

COMMIT;

-- EXCEPTION
--     WHEN OTHERS THEN
--         RAISE;
END;

$BODY$;
ALTER PROCEDURE sas_visual_analytics.sas_3_usp_refresh_informatii_de_business_publish()
    OWNER TO pgadmin;
