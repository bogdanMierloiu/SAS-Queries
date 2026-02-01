-- Toți indecșii legați de tabelă
SELECT schemaname, tablename, indexname, indexdef, a.*
FROM pg_indexes a
WHERE schemaname = 'integration'
AND tablename like '%citire%';


-- Optimizare DWH

CREATE OR REPLACE FUNCTION sas_visual_analytics.immutable_to_date(text, text)
RETURNS date AS
$$
    SELECT to_date($1, $2);
$$
LANGUAGE sql IMMUTABLE;

SELECT NOW()::date;

drop index
CREATE INDEX CONCURRENTLY idx_bill39_gn_date_cast
ON integration.bill39_gn (sas_visual_analytics.immutable_to_date(data_facturare, 'DD.MM.YYYY'));

CREATE INDEX CONCURRENTLY idx_bill39_ee_date_cast
ON integration.bill39_ee (sas_visual_analytics.immutable_to_date(data_facturare, 'DD.MM.YYYY'));


-- Now create the index using the immutable function
CREATE INDEX CONCURRENTLY idx_bill39_gn_date_cast
ON integration.bill39_gn (sas_visual_analytics.immutable_to_date(data_facturare, 'DD.MM.YYYY'));

CREATE INDEX CONCURRENTLY idx_bill39_ee_date_cast
ON integration.bill39_ee (sas_visual_analytics.immutable_to_date(data_facturare, 'DD.MM.YYYY'));

-- Expression index with date casting
CREATE INDEX CONCURRENTLY idx_bill39_gn_date_cast ON integration.bill39_gn (to_date(data_facturare, 'DD.MM.YYYY'));
CREATE INDEX CONCURRENTLY idx_bill39_ee_date_cast ON integration.bill39_ee (to_date(data_facturare, 'DD.MM.YYYY'));

CREATE INDEX idx_bill39_ee_punct_factura ON integration.bill39_ee (punct_de_consum);
CREATE INDEX idx_bill39_gn_punct_factura ON integration.bill39_gn (punct_de_consum);
--
CREATE INDEX idx_contor_equnr ON integration.contor (equnr);

-- index pentru intervalul activ
CREATE INDEX idx_contor_datab_datbi
    ON integration.contor (sas_visual_analytics.immutable_to_date(datab::text, 'YYYYMMDD'), sas_visual_analytics.immutable_to_date(datbi::text, 'YYYYMMDD'));

-- index pentru devloc (legătură cu lc)
CREATE INDEX idx_contor_devloc
    ON integration.contor (devloc)
    WHERE devloc IS NOT NULL;

-- index principal pentru join-uri
CREATE INDEX idx_citire_equnr_zwnummer
    ON integration.citire (equnr, zwnummer);

-- index pe coloana folosită pentru conversia la dată
CREATE INDEX idx_citire_adat
    ON integration.citire (sas_visual_analytics.immutable_to_date(adat::text, 'YYYYMMDD'));

CREATE INDEX idx_contor_registri_equnr_zwnummer ON integration.contor_registri (equnr, zwnummer);

--Debug
SELECT -- CAST(data_facturare AS DATE) as data_facturare_date,
to_date(data_facturare, 'DD.MM.YYYY') as data_facturare_date,
(current_date - interval '3 month')::date AS data_filtrare, *
FROM integration.bill39_ee
WHERE punct_de_consum = '5001656721'
  AND data_facturare = '04.10.2022'

SELECT COUNT(1),
		date_trunc('month', to_date(data_facturare, 'DD.MM.YYYY')) AS luna--,
		--to_date(data_facturare, 'DD.MM.YYYY') AS data_facturare
FROM integration.bill39_gn
WHERE 1=1
-- AND date_trunc('year', to_date(data_facturare, 'DD.MM.YYYY')) =  date '2025-01-01'
-- CAST(data_facturare AS DATE) BETWEEN '2025-10-01'::date AND '2025-10-31'::date
-- AND to_date(data_facturare, 'DD.MM.YYYY') BETWEEN '2025-01-01' AND '2025-12-31'
AND to_date(data_facturare, 'DD.MM.YYYY') >= (current_date - interval '7 month')::date
group by date_trunc('month', to_date(data_facturare, 'DD.MM.YYYY'))
order by luna desc;

select * from integration.bill39_gn
where punct_de_consum = '5003251294'
  AND to_date(data_facturare, 'DD.MM.YYYY') BETWEEN '2025-01-01' AND '2025-05-30'
-- to_date(data_facturare, 'DD.MM.YYYY') >= (current_date - interval '2 month')::date
and punct_de_consum = '5003251294'
-- 01.2025: 1755532
-- 02.2025: 1737349
-- 03.2025: 1731764
select 1800000 * 3

-- aici trebuie sa luam o decizie cate luni in spate mergem? momentan

EXPLAIN ANALYZE
SELECT * FROM integration.bill39_ee
WHERE to_date(data_facturare, 'DD.MM.YYYY')
      BETWEEN '2024-01-01' AND '2024-12-31';



--"04.10.2022"
VACUUM (ANALYZE, VERBOSE) integration.bill39_ee;
VACUUM (ANALYZE, VERBOSE) integration.bill39_gn;

SELECT count(1) FROM integration.v_bill39_filtered_v2 -- 70.071

SELECT relname AS tabela,
       last_analyze,
       last_autoanalyze,
       n_tup_ins,
       n_tup_upd,
       n_tup_del,
       n_live_tup,
       n_dead_tup
FROM pg_stat_all_tables
WHERE relname = 'nume_tabela';

VACUUM ANALYZE integration.bill39_ee;
VACUUM ANALYZE integration.bill39_gn;

SELECT attname,
       null_frac,
       n_distinct,
       most_common_vals,
       most_common_freqs, a.*
FROM pg_stats a
WHERE  schemaname = 'integration' AND tablename = 'bill39_ee';



------------------

-- extensia trebuie instalată pe cluster (ca superuser)
CREATE EXTENSION IF NOT EXISTS pg_partman;

-- creăm tabelul "parent"
CREATE TABLE integration.bill39_ee_partitioned (
    punct_de_consum BIGINT,
    numar_factura BIGINT,
    data_facturare DATE,
    localitate TEXT,
    judet TEXT,
    valoare_totala_energie_lei NUMERIC
);

-- lăsăm partman să gestioneze partitionarea pe data_facturare
SELECT partman.create_parent(
    p_parent_table := 'integration.bill39_ee_partitioned',
    p_control := 'data_facturare',
    p_type := 'native',
    p_interval := '1 month'
);


--

-- Get size of each table in GB
SELECT
    schemaname AS schema_name,
    tablename AS table_name,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS total_size,
    ROUND(pg_total_relation_size(schemaname||'.'||tablename) / 1024.0 / 1024.0 / 1024.0, 4) AS size_in_gb,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS table_size,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename)) AS indexes_size
FROM
    pg_tables
WHERE
    schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY
    pg_total_relation_size(schemaname||'.'||tablename) DESC;


