CREATE OR REPLACE PROCEDURE sas_visual_analytics.usp_refresh_informatii_de_business_publish()
LANGUAGE plpgsql
AS $$
BEGIN

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
        ind_sector_desc
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
        p.ind_sector_desc
    FROM sas_visual_analytics.business_bill_39 b
    LEFT JOIN integration.partner p
           ON b.partener_de_afaceri = p.partner;

EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END;
$$;
