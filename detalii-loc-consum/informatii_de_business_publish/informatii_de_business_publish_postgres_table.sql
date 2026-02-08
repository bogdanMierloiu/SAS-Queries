-- =====================================================================
-- 1) sas_visual_analytics.business_bill_39
--    Base table from bill39_ee / bill39_gn (the latest invoice per punct_de_consum)
--    Columns are ordered to match the logical order used downstream.
-- =====================================================================

DROP TABLE IF EXISTS sas_visual_analytics.business_bill_39;

CREATE TABLE sas_visual_analytics.business_bill_39 (
    -- Identifiers (loc consum)
    punct_de_consum      BIGINT PRIMARY KEY,
    punct_de_consum_str  TEXT,
    numar_instalatie     TEXT,

    -- Customer / partner
    partener_de_afaceri  TEXT,

    -- Contract / invoicing
    clasa_contract       TEXT,
    categorie_tarif      TEXT,
    tip_facturare        TEXT,
    invoicing_party      TEXT,
    nivel_tensiune       TEXT,
    urban_rural          TEXT,

    -- Address
    judet                TEXT,
    localitate           TEXT,
    strada               TEXT,
    subregiune           TEXT
);

CREATE INDEX IF NOT EXISTS idx_bb39_partener_de_afaceri ON sas_visual_analytics.business_bill_39(partener_de_afaceri);
CREATE INDEX IF NOT EXISTS idx_bb39_judet               ON sas_visual_analytics.business_bill_39(judet);
CREATE INDEX IF NOT EXISTS idx_bb39_localitate          ON sas_visual_analytics.business_bill_39(localitate);

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

-- sanity
SELECT COUNT(*) FROM sas_visual_analytics.business_bill_39;



-- =====================================================================
-- 2) sas_visual_analytics.informatii_de_business_publish
--    Final table for Dashboard 2 (Identity + Business)
--    Columns are ordered exactly in the logical display order.
-- =====================================================================

DROP TABLE IF EXISTS sas_visual_analytics.informatii_de_business_publish;

CREATE TABLE sas_visual_analytics.informatii_de_business_publish (
    -- 1) Identifiers (loc consum)
    punct_de_consum      BIGINT PRIMARY KEY,
    punct_de_consum_str  TEXT,
    numar_instalatie     TEXT,

    -- 2) Customer / partner
    partener_de_afaceri  TEXT,
    name                 TEXT,
    reg_number           TEXT,
    cif_number           TEXT,

    -- 3) Contract / invoicing
    clasa_contract       TEXT,
    categorie_tarif      TEXT,
    tip_facturare        TEXT,
    invoicing_party      TEXT,
    nivel_tensiune       TEXT,
    urban_rural          TEXT,

    -- 4) Address
    judet                TEXT,
    localitate           TEXT,
    strada               TEXT,
    subregiune           TEXT,

    -- 5) Regions
    region               TEXT,
    region_name          TEXT,
    city                 TEXT,

    -- 6) Sector
    ind_sector           TEXT,
    ind_sector_desc      TEXT
);

CREATE INDEX IF NOT EXISTS idx_idbp_pdc       ON sas_visual_analytics.informatii_de_business_publish(punct_de_consum);
CREATE INDEX IF NOT EXISTS idx_idbp_pdc_str   ON sas_visual_analytics.informatii_de_business_publish(punct_de_consum_str);
CREATE INDEX IF NOT EXISTS idx_idbp_partner   ON sas_visual_analytics.informatii_de_business_publish(partener_de_afaceri);
CREATE INDEX IF NOT EXISTS idx_idbp_judet     ON sas_visual_analytics.informatii_de_business_publish(judet);
CREATE INDEX IF NOT EXISTS idx_idbp_localitate ON sas_visual_analytics.informatii_de_business_publish(localitate);

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

-- sanity
SELECT COUNT(*) FROM sas_visual_analytics.informatii_de_business_publish;

-- example
SELECT *
FROM sas_visual_analytics.informatii_de_business_publish
WHERE punct_de_consum = 5001689479;
