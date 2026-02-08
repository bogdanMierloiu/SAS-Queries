DROP TABLE IF EXISTS sas_visual_analytics.tmp_bill_39;

CREATE TABLE sas_visual_analytics.tmp_bill_39 (
    punct_de_consum TEXT PRIMARY KEY,
    localitate TEXT,
    judet TEXT,
    subregiune TEXT,
    clasa_contract TEXT,
    partener_de_afaceri_descriere TEXT
);

CREATE INDEX IF NOT EXISTS idx_tmp_bill39_localitate ON sas_visual_analytics.tmp_bill_39(localitate);
CREATE INDEX IF NOT EXISTS idx_tmp_bill39_judet ON sas_visual_analytics.tmp_bill_39(judet);
CREATE INDEX IF NOT EXISTS idx_tmp_bill39_subregiune ON sas_visual_analytics.tmp_bill_39(subregiune);


TRUNCATE TABLE sas_visual_analytics.tmp_bill_39;

WITH params AS (
    SELECT
        (current_date - interval '3 years')::date AS start_date,
        current_date::date AS end_date
),
ee_last AS (
    SELECT DISTINCT ON (b.punct_de_consum)
        b.punct_de_consum,
        b.localitate,
        CASE WHEN b.judet = 'VR' THEN 'VN' ELSE b.judet END AS judet,
        b.subregiune,
        b.clasa_contract,
        b.partener_de_afaceri_descriere
    FROM integration.bill39_ee b
    CROSS JOIN params p
    WHERE b.punct_de_consum IS NOT NULL
      AND sas_visual_analytics.immutable_to_date(b.data_facturare, 'DD.MM.YYYY') >= p.start_date
      AND sas_visual_analytics.immutable_to_date(b.data_facturare, 'DD.MM.YYYY') <= p.end_date
    ORDER BY
        b.punct_de_consum,
        sas_visual_analytics.immutable_to_date(b.data_facturare, 'DD.MM.YYYY') DESC,
        b.numar_factura DESC
),
gn_last AS (
    SELECT DISTINCT ON (b.punct_de_consum)
        b.punct_de_consum,
        b.localitate,
        CASE WHEN b.judet = 'VR' THEN 'VN' ELSE b.judet END AS judet,
        b.subregiune,
        b.clasa_contract,
        b.partener_de_afaceri_descriere
    FROM integration.bill39_gn b
    CROSS JOIN params p
    WHERE b.punct_de_consum IS NOT NULL
      AND sas_visual_analytics.immutable_to_date(b.data_facturare, 'DD.MM.YYYY') >= p.start_date
      AND sas_visual_analytics.immutable_to_date(b.data_facturare, 'DD.MM.YYYY') <= p.end_date
    ORDER BY
        b.punct_de_consum,
        sas_visual_analytics.immutable_to_date(b.data_facturare, 'DD.MM.YYYY') DESC,
        b.numar_factura DESC
),
combined AS (
    SELECT * FROM ee_last
    UNION ALL
    SELECT * FROM gn_last
)
INSERT INTO sas_visual_analytics.tmp_bill_39 (
    punct_de_consum,
    localitate,
    judet,
    subregiune,
    clasa_contract,
    partener_de_afaceri_descriere
)
SELECT DISTINCT ON (punct_de_consum)
    punct_de_consum,
    localitate,
    judet,
    subregiune,
    clasa_contract,
    partener_de_afaceri_descriere
FROM combined
ORDER BY punct_de_consum;



select count(1) from sas_visual_analytics.tmp_bill_39



DROP TABLE IF EXISTS sas_visual_analytics.tmp_ci_clean;

CREATE TABLE sas_visual_analytics.tmp_ci_clean (
    devloc TEXT PRIMARY KEY,
    sursa_complexitate TEXT,
    complexitate_instalatie INT
);

CREATE INDEX IF NOT EXISTS idx_tmp_ci_complexitate ON sas_visual_analytics.tmp_ci_clean(complexitate_instalatie);
CREATE INDEX IF NOT EXISTS idx_tmp_ci_sursa ON sas_visual_analytics.tmp_ci_clean(sursa_complexitate);

TRUNCATE TABLE sas_visual_analytics.tmp_ci_clean;

INSERT INTO sas_visual_analytics.tmp_ci_clean (devloc, sursa_complexitate, complexitate_instalatie)
SELECT
    ci.devloc,
    ci.sursa_complexitate,
    ci.complexitate_instalatie
FROM sas_visual_analytics.complexitate_instalatie ci
INNER JOIN (SELECT devloc,
			       MAX(complexitate_instalatie) AS complexitate_instalatie
			FROM sas_visual_analytics.complexitate_instalatie
			GROUP BY devloc
			) ci_max ON ci.devloc = ci_max.devloc
			        AND ci.complexitate_instalatie = ci_max.complexitate_instalatie;





DROP TABLE IF EXISTS sas_visual_analytics.rezultate_frauda_publish;

CREATE TABLE sas_visual_analytics.rezultate_frauda_publish (
    probabilitate_de_frauda      NUMERIC,
    localitate                   TEXT,
    judet                        TEXT,
    punct_de_consum_str          TEXT,
    punct_de_consum              BIGINT,
    clasa_contract               TEXT,
    partener_de_afaceri_descriere TEXT,
    complexitate_instalatie      INT,

    gps_lat                      DOUBLE PRECISION,
    gps_lon                      DOUBLE PRECISION,

    tip_energie                  TEXT,
    tip_energie_measure          NUMERIC,
    sursa_complexitate           TEXT
);

CREATE INDEX IF NOT EXISTS idx_rez_frauda_punct ON sas_visual_analytics.rezultate_frauda_publish(punct_de_consum);
CREATE INDEX IF NOT EXISTS idx_rez_frauda_judet ON sas_visual_analytics.rezultate_frauda_publish(judet);
CREATE INDEX IF NOT EXISTS idx_rez_frauda_localitate ON sas_visual_analytics.rezultate_frauda_publish(localitate);

TRUNCATE TABLE sas_visual_analytics.rezultate_frauda_publish;

INSERT INTO sas_visual_analytics.rezultate_frauda_publish
SELECT
    p.probabilitate_de_frauda,
    b.localitate,
    b.judet,
    b.punct_de_consum::text AS punct_de_consum_str,
    CAST(b.punct_de_consum AS BIGINT) AS punct_de_consum,
    b.clasa_contract,
    b.partener_de_afaceri_descriere,

    CASE
        WHEN cnt.sparte = '01' THEN ci.complexitate_instalatie
        WHEN cnt.sparte = '02' THEN 1
    END AS complexitate_instalatie,

    CASE
        WHEN trim(lc.gps_lat) ~ '^[+-]?[0-9]+(\.[0-9]+)?$'
             AND abs(trim(lc.gps_lat)::double precision) <= 90
        THEN NULLIF(trim(lc.gps_lat)::double precision, 0)
        ELSE NULL
    END AS gps_lat,

    CASE
        WHEN trim(lc.gps_lon) ~ '^[+-]?[0-9]+(\.[0-9]+)?$'
             AND abs(trim(lc.gps_lon)::double precision) <= 180
        THEN NULLIF(trim(lc.gps_lon)::double precision, 0)
        ELSE NULL
    END AS gps_lon,

    CASE
        WHEN cnt.sparte = '01' THEN 'Electricitate'
        WHEN cnt.sparte = '02' THEN 'Gaz'
        ELSE 'N/A'
    END AS tip_energie,
    CASE
            WHEN cnt.sparte = '01' THEN 1
            WHEN cnt.sparte = '02' THEN 2
            ELSE 3
        END AS tip_energie_measure,
    ci.sursa_complexitate
FROM sas_visual_analytics.tmp_bill_39 b
INNER JOIN integration.lc lc ON b.punct_de_consum = lc.vstelle
INNER JOIN integration.probabilitate p ON b.punct_de_consum = p.nlc
INNER JOIN sas_visual_analytics.contor_clean cnt ON lc.devloc = cnt.devloc
                                                        AND cnt.sparte IN ('01', '02')
INNER JOIN sas_visual_analytics.tmp_ci_clean ci ON ci.devloc = lc.devloc;

--SELECT * FROM sas_visual_analytics.rezultate_frauda_publish WHERE punct_de_consum = '5001656721';
--SELECT COUNT(*) FROM sas_visual_analytics.rezultate_frauda_publish
--3.619.494

