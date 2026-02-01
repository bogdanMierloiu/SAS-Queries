-- Creează tabela sas_visual_analytics.contor_clean pe baza integration.contor
-- Selectează doar echipamente de tip contor, valabile în prezent (CURRENT_DATE între datab și datbi),
-- care au descrierea conținând MONO sau TRI.
-- Calculează complexitatea instalației (1 pentru MONO, 3 pentru TRI).
-- Convertește datele datab/datbi în format DATE.
-- Folosește DISTINCT ON pentru a păstra o singură înregistrare per devloc,
-- alegând varianta cu complexitatea mai mare (TRI > MONO).


-- SELECT * FROM sas_visual_analytics.contor_clean
-- WHERE devloc = '7000921061'
-- limit 100

-- SELECT COUNT(*) FROM sas_visual_analytics.contor_clean
--2.807.464

CREATE TABLE IF NOT EXISTS sas_visual_analytics.contor_clean (
    devloc TEXT PRIMARY KEY,
    equnr TEXT,
    sparte TEXT,
    complexitate_instalatie INT,
    datab_d DATE,
    datbi_d DATE
);

CREATE INDEX IF NOT EXISTS idx_contor_clean_equnr ON sas_visual_analytics.contor_clean(equnr);
CREATE INDEX IF NOT EXISTS idx_contor_clean_sparte ON sas_visual_analytics.contor_clean(sparte);
CREATE INDEX IF NOT EXISTS idx_contor_clean_datab_datbi ON sas_visual_analytics.contor_clean(datab_d, datbi_d);

TRUNCATE TABLE sas_visual_analytics.contor_clean;

INSERT INTO sas_visual_analytics.contor_clean (
    devloc, equnr, sparte, complexitate_instalatie, datab_d, datbi_d
)
SELECT DISTINCT ON (c.devloc)
    c.devloc,
    c.equnr,
    c.sparte,
    CASE
        WHEN UPPER(c.matnr_desc) LIKE '%MONO%' THEN 1
        WHEN UPPER(c.matnr_desc) LIKE '%TRI%'  THEN 3
        ELSE 1
    END AS complexitate_instalatie,
    TO_DATE(c.datab::text, 'YYYYMMDD') AS datab_d,
    TO_DATE(c.datbi::text, 'YYYYMMDD') AS datbi_d
FROM integration.contor c
WHERE c.devloc IS NOT NULL
  AND c.datab IS NOT NULL
  AND c.datbi IS NOT NULL
  AND c.gertyptxtl = 'contor'
  AND CURRENT_DATE BETWEEN TO_DATE(c.datab::text, 'YYYYMMDD')
                        AND TO_DATE(c.datbi::text, 'YYYYMMDD')
ORDER BY c.devloc,
         CASE
            WHEN UPPER(c.matnr_desc) LIKE '%MONO%' THEN 1
            WHEN UPPER(c.matnr_desc) LIKE '%TRI%'  THEN 3
            ELSE 1
         END DESC;
