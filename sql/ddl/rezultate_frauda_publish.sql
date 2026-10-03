-- Table: sas_visual_analytics.rezultate_frauda_publish

-- DROP TABLE IF EXISTS sas_visual_analytics.rezultate_frauda_publish;

CREATE TABLE IF NOT EXISTS sas_visual_analytics.rezultate_frauda_publish
(
    probabilitate_de_frauda numeric,
    localitate text COLLATE pg_catalog."default",
    judet text COLLATE pg_catalog."default",
    punct_de_consum_str text COLLATE pg_catalog."default",
    punct_de_consum bigint,
    clasa_contract text COLLATE pg_catalog."default",
    partener_de_afaceri_descriere text COLLATE pg_catalog."default",
    complexitate_instalatie integer,
    gps_lat double precision,
    gps_lon double precision,
    tip_energie text COLLATE pg_catalog."default",
    tip_energie_measure numeric,
    sursa_complexitate text COLLATE pg_catalog."default",
    verificat boolean,
    loading_dttm timestamp(0) without time zone
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS sas_visual_analytics.rezultate_frauda_publish
    OWNER to pgadmin;
-- Index: idx_rez_frauda_judet

-- DROP INDEX IF EXISTS sas_visual_analytics.idx_rez_frauda_judet;

CREATE INDEX IF NOT EXISTS idx_rez_frauda_judet
    ON sas_visual_analytics.rezultate_frauda_publish USING btree
    (judet COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: idx_rez_frauda_localitate

-- DROP INDEX IF EXISTS sas_visual_analytics.idx_rez_frauda_localitate;

CREATE INDEX IF NOT EXISTS idx_rez_frauda_localitate
    ON sas_visual_analytics.rezultate_frauda_publish USING btree
    (localitate COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: idx_rez_frauda_punct

-- DROP INDEX IF EXISTS sas_visual_analytics.idx_rez_frauda_punct;

CREATE INDEX IF NOT EXISTS idx_rez_frauda_punct
    ON sas_visual_analytics.rezultate_frauda_publish USING btree
    (punct_de_consum ASC NULLS LAST)
    TABLESPACE pg_default;