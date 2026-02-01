DROP TABLE IF EXISTS sas_visual_analytics.transformator_clean;

CREATE TABLE sas_visual_analytics.transformator_clean (
    devloc TEXT PRIMARY KEY,
    complexitate_instalatie INT
);

CREATE INDEX IF NOT EXISTS idx_transformator_clean_complexitate
    ON sas_visual_analytics.transformator_clean (complexitate_instalatie);

TRUNCATE TABLE sas_visual_analytics.transformator_clean;


INSERT INTO sas_visual_analytics.transformator_clean (devloc, complexitate_instalatie)
WITH base AS (
    SELECT
        t.devloc,
        t.wgruppe,
        -- tip: tot ce e inainte de primul digit
        substring(t.wgruppe from '^[^0-9]*') AS tip,
        -- pastreaza doar cifrele si slash-ul
        regexp_replace(t.wgruppe, '[^0-9/]', '', 'g') AS numere_doar
    FROM integration.transformator t
    WHERE t.gertyptxtl = 'transformat'
	  AND t.devloc IS NOT NULL
      AND t.wgruppe IS NOT NULL
      AND t.wgruppe LIKE '%/%'
),
vals AS (
    SELECT
        b.devloc,
        b.wgruppe,
        b.tip,
        b.numere_doar,
        NULLIF(split_part(b.numere_doar, '/', 1), '')::numeric AS val_primar,
        CASE
            WHEN split_part(b.numere_doar, '/', 2) IN ('', '0', '00') THEN NULL
            WHEN split_part(b.numere_doar, '/', 2) ~ '^0[0-9]+'
                THEN ('0.' || substring(split_part(b.numere_doar, '/', 2) FROM 2))::numeric
            ELSE split_part(b.numere_doar, '/', 2)::numeric
        END AS val_secundar
    FROM base b
),
rt AS (
    SELECT
        v.devloc,
        v.wgruppe,
        CASE
            WHEN v.val_secundar IS NOT NULL AND v.val_secundar <> 0
                THEN v.val_primar / v.val_secundar
        END AS raport_transformare
    FROM vals v
),
distinct_rt AS (SELECT DISTINCT devloc, wgruppe, raport_transformare from rt)
SELECT devloc,
	   CAST(3 * SUM(raport_transformare) AS INT) AS complexitate_instalatie
  FROM distinct_rt
 GROUP BY devloc;

-- vizualizare date
SELECT * FROM sas_visual_analytics.transformator_clean;

