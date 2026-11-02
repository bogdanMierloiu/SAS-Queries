-- =====================================================================
-- 05 - consum_silver: duplicates behind the line chart
-- Chart grain: Category = data_citire, Group = kennziff, Measure = consum
-- PK is (equnr, zwnummer, data_citire) -> kennziff and punct_de_consum
-- are NOT in the key, so several rows can collide at the chart grain
-- and make the line chart "double up" / zig-zag.
-- =====================================================================

-- 1) Duplicates at the chart grain, per consumption point
--    (punct_de_consum, kennziff, data_citire).
--    These are the rows that break a per-point line chart.
SELECT punct_de_consum,
       kennziff,
       data_citire,
       COUNT(*)                        AS n_rows,
       COUNT(DISTINCT equnr)           AS n_equnr,
       COUNT(DISTINCT zwnummer)        AS n_zwnummer,
       COUNT(DISTINCT sernr)           AS n_sernr,
       MIN(index)                      AS index_min,
       MAX(index)                      AS index_max,
       MIN(consum)                     AS consum_min,
       MAX(consum)                     AS consum_max
FROM sas_visual_analytics.consum_silver
GROUP BY punct_de_consum, kennziff, data_citire
HAVING COUNT(*) > 1
ORDER BY n_rows DESC, punct_de_consum, kennziff, data_citire;

-- 2) Same as above but WITHOUT the point (global grain of the chart when
--    no point filter is applied): (kennziff, data_citire).
SELECT kennziff,
       data_citire,
       COUNT(*) AS n_rows
FROM sas_visual_analytics.consum_silver
GROUP BY kennziff, data_citire
HAVING COUNT(*) > 1
ORDER BY n_rows DESC, kennziff, data_citire
LIMIT 100;

-- 3) Full detail of the duplicated rows (to decide which one to keep).
--    Returns every physical row that participates in a duplicate group
--    at the (punct_de_consum, kennziff, data_citire) grain.
WITH dups AS (
    SELECT punct_de_consum, kennziff, data_citire
    FROM sas_visual_analytics.consum_silver
    GROUP BY punct_de_consum, kennziff, data_citire
    HAVING COUNT(*) > 1
)
SELECT s.punct_de_consum,
       s.kennziff,
       s.data_citire,
       s.equnr,
       s.zwnummer,
       s.sernr,
       s.index,
       s.consum,
       s.massread,
       s.loading_dttm,
       ROW_NUMBER() OVER (
           PARTITION BY s.punct_de_consum, s.kennziff, s.data_citire
           ORDER BY s.loading_dttm DESC NULLS LAST, s.equnr, s.zwnummer
       ) AS rn
FROM sas_visual_analytics.consum_silver s
JOIN dups d
  ON  d.punct_de_consum = s.punct_de_consum
 AND d.kennziff         = s.kennziff
 AND d.data_citire      = s.data_citire
ORDER BY s.punct_de_consum, s.kennziff, s.data_citire,
         s.loading_dttm DESC NULLS LAST;

-- 4) Deduplicated feed for the chart: keep only ONE row per
--    (punct_de_consum, kennziff, data_citire), latest load wins.
--    Point this (or a view built on it) as the chart data source.
SELECT *
FROM (
    SELECT s.*,
           ROW_NUMBER() OVER (
               PARTITION BY s.punct_de_consum, s.kennziff, s.data_citire
               ORDER BY s.loading_dttm DESC NULLS LAST, s.equnr, s.zwnummer
           ) AS rn
    FROM sas_visual_analytics.consum_silver s
) t
WHERE rn = 1
ORDER BY punct_de_consum, kennziff, data_citire;
