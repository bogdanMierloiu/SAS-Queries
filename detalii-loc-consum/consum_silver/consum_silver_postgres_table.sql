DROP TABLE IF EXISTS sas_visual_analytics.raw_filtered_data;

CREATE TABLE sas_visual_analytics.raw_filtered_data (
    equnr TEXT,
    sernr TEXT,
    zwnummer TEXT,
    data_citire DATE,
    index_val NUMERIC,
    kennziff TEXT,
    massread TEXT,
    punct_de_consum_str TEXT,
    punct_de_consum BIGINT,
    datab_d DATE,
    datbi_d DATE,
    PRIMARY KEY (equnr, zwnummer, data_citire)
);

CREATE INDEX IF NOT EXISTS idx_raw_punct ON sas_visual_analytics.raw_filtered_data(punct_de_consum);
CREATE INDEX IF NOT EXISTS idx_raw_data_citire ON sas_visual_analytics.raw_filtered_data(data_citire);
CREATE INDEX IF NOT EXISTS idx_raw_equnr_zwnummer ON sas_visual_analytics.raw_filtered_data(equnr, zwnummer);

TRUNCATE TABLE sas_visual_analytics.raw_filtered_data;

INSERT INTO sas_visual_analytics.raw_filtered_data (
    equnr, sernr, zwnummer, data_citire, index_val, kennziff, massread,
    punct_de_consum_str, punct_de_consum, datab_d, datbi_d
)
SELECT DISTINCT ON (c.equnr, c.zwnummer, c.data_citire)
    c.equnr,
    c.sernr,
    c.zwnummer,
    c.data_citire,
    c.v_zwstand::numeric AS index,
    CASE
        WHEN cr.kennziff IS NULL OR TRIM(cr.kennziff) = '' THEN 'gaz'
        ELSE cr.kennziff
    END AS kennziff,
    cr.massread,
    lc.vstelle::text AS punct_de_consum_str,
    lc.vstelle::bigint AS punct_de_consum,
	cnt.datab as datab_d, cnt.datbi AS datbi_d
FROM (SELECT *, TO_DATE(adat::text, 'YYYYMMDD') AS data_citire
        FROM integration.citire) c
INNER JOIN (
    SELECT DISTINCT ON (equnr, zwnummer)
       equnr, zwnummer,
       COALESCE(NULLIF(TRIM(kennziff), ''), 'gaz') AS kennziff,
       massread
    FROM integration.contor_registri
) cr
  ON c.equnr = cr.equnr
 AND c.zwnummer = cr.zwnummer
INNER JOIN (
    SELECT
        devloc, sernr, equnr,
        TO_DATE(datab::text, 'YYYYMMDD') AS datab,
        TO_DATE(datbi::text, 'YYYYMMDD') AS datbi
    FROM integration.contor
    WHERE CURRENT_DATE BETWEEN TO_DATE(datab::text, 'YYYYMMDD') AND TO_DATE(datbi::text, 'YYYYMMDD')
	  AND devloc IS NOT NULL
      AND datab IS NOT NULL
      AND datbi IS NOT NULL
) cnt ON cnt.equnr = cr.equnr
INNER JOIN integration.lc lc ON lc.devloc = cnt.devloc
WHERE 1=1
  AND c.v_zwstand IS NOT NULL
  AND c.v_zwstand::integer > 0
  AND c.adat IS NOT NULL
  AND c.adat <> '00000000'
  AND c.data_citire BETWEEN DATE '2023-06-01' AND CURRENT_DATE
  AND lc.vstelle IS NOT NULL;


-- o ora si 35 minute pt 2,5 ani de rulare
select count(*) from sas_visual_analytics.raw_filtered_data
--95.489.310


SELECT * FROM sas_visual_analytics.raw_filtered_data WHERE equnr = '000000008008601244';


DROP TABLE IF EXISTS sas_visual_analytics.consum_calculat;

CREATE TABLE sas_visual_analytics.consum_calculat (
    equnr TEXT,
    sernr TEXT,
    zwnummer TEXT,
    kennziff TEXT,
    punct_de_consum BIGINT,
    punct_de_consum_str TEXT,
    data_citire DATE,
    index_val NUMERIC,
    datab_d DATE,
    datbi_d DATE,
    massread TEXT,
    consum NUMERIC,
    PRIMARY KEY (equnr, zwnummer, data_citire)
);


CREATE INDEX IF NOT EXISTS idx_consumcalc_punct ON sas_visual_analytics.consum_calculat(punct_de_consum);
CREATE INDEX IF NOT EXISTS idx_consumcalc_data_citire ON sas_visual_analytics.consum_calculat(data_citire);


TRUNCATE TABLE sas_visual_analytics.consum_calculat;

INSERT INTO sas_visual_analytics.consum_calculat (
    equnr, sernr, zwnummer, kennziff, punct_de_consum,
    punct_de_consum_str, data_citire, index_val, datab_d,
    datbi_d, massread, consum
)
SELECT
    equnr,
    sernr,
    zwnummer,
    kennziff,
    punct_de_consum,
    punct_de_consum_str,
    data_citire,
    index_val,
    datab_d,
    datbi_d,
    massread,
    index_val - LAG(index_val) OVER (PARTITION BY equnr, zwnummer, kennziff ORDER BY data_citire) AS consum
FROM sas_visual_analytics.raw_filtered_data
WHERE data_citire IS NOT NULL
  AND index_val > 0


SELECT * FROM sas_visual_analytics.consum_calculat WHERE equnr = '000000008008601244';


------------------------

DROP TABLE IF EXISTS sas_visual_analytics.consum_silver;

CREATE TABLE sas_visual_analytics.consum_silver (
    equnr TEXT,
    sernr TEXT,
    zwnummer TEXT,
    kennziff TEXT,
    punct_de_consum BIGINT,
    punct_de_consum_str TEXT,
    data_citire DATE,
    index NUMERIC,
    consum NUMERIC,
    datab_d DATE,
    datbi_d DATE,
    massread TEXT,
    PRIMARY KEY (equnr, zwnummer, data_citire)
);

CREATE INDEX IF NOT EXISTS idx_silver_punct ON sas_visual_analytics.consum_silver(punct_de_consum);
CREATE INDEX IF NOT EXISTS idx_silver_data ON sas_visual_analytics.consum_silver(data_citire DESC);


TRUNCATE TABLE sas_visual_analytics.consum_silver;

INSERT INTO sas_visual_analytics.consum_silver (
    equnr, sernr, zwnummer, kennziff, punct_de_consum,
    punct_de_consum_str, data_citire, index, consum, datab_d, datbi_d, massread
)
SELECT
    equnr,
    sernr,
    zwnummer,
    kennziff,
    punct_de_consum,
    punct_de_consum_str,
    data_citire,
    index_val AS index,
    ROUND(consum, 2) AS consum,
    datab_d,
    datbi_d,
    massread
FROM sas_visual_analytics.consum_calculat
WHERE consum IS NOT NULL
  AND consum > 0
ORDER BY data_citire DESC, kennziff, zwnummer;


SELECT COUNT(*) FROM sas_visual_analytics.consum_silver;
--74.736.748
-- 2 ore si 9 minute pt 2,5 ani de rulare



