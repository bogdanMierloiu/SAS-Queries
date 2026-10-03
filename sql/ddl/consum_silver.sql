-- Table: sas_visual_analytics.consum_silver

-- DROP TABLE IF EXISTS sas_visual_analytics.consum_silver;

CREATE TABLE IF NOT EXISTS sas_visual_analytics.consum_silver
(
    equnr text COLLATE pg_catalog."default" NOT NULL,
    sernr text COLLATE pg_catalog."default",
    zwnummer text COLLATE pg_catalog."default" NOT NULL,
    kennziff text COLLATE pg_catalog."default",
    punct_de_consum bigint,
    punct_de_consum_str text COLLATE pg_catalog."default",
    data_citire date NOT NULL,
    index numeric,
    consum numeric,
    massread text COLLATE pg_catalog."default",
    loading_dttm timestamp(0) without time zone,
    CONSTRAINT consum_silver_pkey PRIMARY KEY (equnr, zwnummer, data_citire)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS sas_visual_analytics.consum_silver
    OWNER to pgadmin;
-- Index: idx_silver_data

-- DROP INDEX IF EXISTS sas_visual_analytics.idx_silver_data;

CREATE INDEX IF NOT EXISTS idx_silver_data
    ON sas_visual_analytics.consum_silver USING btree
    (data_citire DESC NULLS FIRST)
    TABLESPACE pg_default;
-- Index: idx_silver_punct

-- DROP INDEX IF EXISTS sas_visual_analytics.idx_silver_punct;

CREATE INDEX IF NOT EXISTS idx_silver_punct
    ON sas_visual_analytics.consum_silver USING btree
    (punct_de_consum ASC NULLS LAST)
    TABLESPACE pg_default;