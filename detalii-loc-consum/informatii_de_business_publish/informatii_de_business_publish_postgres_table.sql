-- select count (*) from integration.partner
-- CREATE INDEX IF NOT EXISTS idx_partner_partner ON integration.partner(partner);

DROP TABLE IF EXISTS sas_visual_analytics.business_bill_39

CREATE TABLE sas_visual_analytics.business_bill_39 (
    punct_de_consum BIGINT PRIMARY KEY,
    punct_de_consum_str TEXT,
    numar_instalatie TEXT,
    partener_de_afaceri TEXT,
    partener_de_afaceri_descriere TEXT,
    clasa_contract TEXT,
    categorie_tarif TEXT,
    tip_facturare TEXT,
    invoicing_party TEXT,
    judet TEXT,
    localitate TEXT,
    strada TEXT,
    subregiune TEXT,
    nivel_tensiune TEXT,
    urban_rural TEXT
);

CREATE INDEX IF NOT EXISTS idx_tmp_bill39_partener_de_afaceri ON sas_visual_analytics.business_bill_39(partener_de_afaceri);

TRUNCATE TABLE sas_visual_analytics.business_bill_39;

WITH params AS (
    SELECT (current_date - interval '3 years')::date AS start_date
),
bill39 AS (
    SELECT *
    FROM (
        SELECT DISTINCT ON (b.punct_de_consum)
            'ee' AS tip,
            b.punct_de_consum,
            b.numar_instalatie,
            b.partener_de_afaceri,
            b.partener_de_afaceri_descriere,
            b.clasa_contract,
            b.categorie_tarif,
            b.tip_facturare,
            b.invoicing_party,
            CASE WHEN b.judet = 'VR' THEN 'VN' ELSE b.judet END AS judet,
            b.localitate,
            b.strada,
            b.subregiune,
            b.nivel_tensiune,
            b.urban_rural
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

    SELECT *
    FROM (
        SELECT DISTINCT ON (b.punct_de_consum)
            'gn' AS tip,
            b.punct_de_consum,
            b.numar_instalatie,
            b.partener_de_afaceri,
            b.partener_de_afaceri_descriere,
            b.clasa_contract,
            b.categorie_tarif,
            b.tip_facturare,
            b.invoicing_party,
            CASE WHEN b.judet = 'VR' THEN 'VN' ELSE b.judet END AS judet,
            b.localitate,
            b.strada,
            b.subregiune,
            b.nivel_tensiune,
            b.urban_rural
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
    partener_de_afaceri_descriere,
    clasa_contract,
    categorie_tarif,
    tip_facturare,
    invoicing_party,
    judet,
    localitate,
    strada,
    subregiune,
    nivel_tensiune,
    urban_rural
)
SELECT DISTINCT ON (a.punct_de_consum)
    a.punct_de_consum::bigint AS punct_de_consum,
    a.punct_de_consum::text   AS punct_de_consum_str,
    a.numar_instalatie,
    a.partener_de_afaceri,
    a.partener_de_afaceri_descriere,
    a.clasa_contract,
    a.categorie_tarif,
    a.tip_facturare,
    a.invoicing_party,
    a.judet,
    a.localitate,
    a.strada,
    a.subregiune,
    a.nivel_tensiune,
    a.urban_rural
FROM bill39 a
ORDER BY
    a.punct_de_consum,
    (a.tip = 'ee') DESC;  -- prefera EE dacă există în ambele

SELECT COUNT(1) FROM sas_visual_analytics.business_bill_39
--3.665.387

DROP TABLE IF EXISTS sas_visual_analytics.informatii_de_business_publish

CREATE TABLE sas_visual_analytics.informatii_de_business_publish
(
    punct_de_consum               BIGINT PRIMARY KEY,
    punct_de_consum_str           TEXT,
    numar_instalatie              TEXT,
    partener_de_afaceri           TEXT,
    partener_de_afaceri_descriere TEXT,
    clasa_contract                TEXT,
    categorie_tarif               TEXT,
    tip_facturare                 TEXT,
    invoicing_party               TEXT,
    judet                         TEXT,
    localitate                    TEXT,
    strada                        TEXT,
    subregiune                    TEXT,
    nivel_tensiune                TEXT,
    urban_rural                   TEXT,
    partner                       TEXT,
    name                          TEXT,
    reg_number                    TEXT,
    cif_number                    TEXT,
    region                        TEXT,
    region_name                   TEXT,
    city                          TEXT,
    ind_sector                    TEXT,
    ind_sector_desc               TEXT
);


CREATE INDEX IF NOT EXISTS idx_tmp_bill39_punct_de_consum ON sas_visual_analytics.informatii_de_business_publish(punct_de_consum);
CREATE INDEX IF NOT EXISTS idx_tmp_bill39_punct_de_consum_str ON sas_visual_analytics.informatii_de_business_publish(punct_de_consum_str);


TRUNCATE TABLE sas_visual_analytics.informatii_de_business_publish;

INSERT INTO sas_visual_analytics.informatii_de_business_publish
(punct_de_consum, punct_de_consum_str, numar_instalatie,
 partener_de_afaceri, partener_de_afaceri_descriere,
 clasa_contract, categorie_tarif, tip_facturare, invoicing_party,
 judet, localitate, strada, subregiune, nivel_tensiune, urban_rural,
 partner, name, reg_number, cif_number, region, region_name, city, ind_sector, ind_sector_desc)
SELECT DISTINCT ON (b.punct_de_consum)
	   b.punct_de_consum,
       b.punct_de_consum_str,
       b.numar_instalatie,
       b.partener_de_afaceri,
       b.partener_de_afaceri_descriere,
       b.clasa_contract,
       b.categorie_tarif,
       b.tip_facturare,
       b.invoicing_party,
       b.judet,
       b.localitate,
       b.strada,
       b.subregiune,
       b.nivel_tensiune,
       b.urban_rural,
       p.partner,
       p.name,
       p.reg_number,
       p.cif_number,
       p.region,
       p.region_name,
       p.city,
       p.ind_sector,
       p.ind_sector_desc
FROM sas_visual_analytics.business_bill_39 b
         JOIN integration.partner p ON b.partener_de_afaceri = p.partner;



SELECT COUNT(*) FROM sas_visual_analytics.informatii_de_business_publish
--3.665.387
SELECT * FROM sas_visual_analytics.informatii_de_business_publish where punct_de_consum = 5001689479
