-- Table: sas_visual_analytics.informatii_verificare_publish

-- DROP TABLE IF EXISTS sas_visual_analytics.informatii_verificare_publish;

CREATE TABLE IF NOT EXISTS sas_visual_analytics.informatii_verificare_publish
(
    id bigint NOT NULL DEFAULT nextval('sas_visual_analytics.informatii_verificare_publish_id_seq'::regclass),
    punct_de_consum bigint,
    punct_de_consum_str text COLLATE pg_catalog."default",
    data date,
    cod_nec_1 text COLLATE pg_catalog."default",
    stare_loc_consum text COLLATE pg_catalog."default",
    sursa_input text COLLATE pg_catalog."default",
    consumator text COLLATE pg_catalog."default",
    divizie text COLLATE pg_catalog."default",
    nr_doc_intocmit_pvsd_bmmm text COLLATE pg_catalog."default",
    nr_nota_de_constatare text COLLATE pg_catalog."default",
    serie_contor text COLLATE pg_catalog."default",
    cantitate text COLLATE pg_catalog."default",
    um text COLLATE pg_catalog."default",
    cod_analiza text COLLATE pg_catalog."default",
    loading_dttm timestamp(0) without time zone,
    CONSTRAINT informatii_verificare_publish_pkey PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS sas_visual_analytics.informatii_verificare_publish
    OWNER to pgadmin;
-- Index: idx_ivp_punct_de_consum

-- DROP INDEX IF EXISTS sas_visual_analytics.idx_ivp_punct_de_consum;

CREATE INDEX IF NOT EXISTS idx_ivp_punct_de_consum
    ON sas_visual_analytics.informatii_verificare_publish USING btree
    (punct_de_consum ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: idx_ivp_punct_de_consum_str

-- DROP INDEX IF EXISTS sas_visual_analytics.idx_ivp_punct_de_consum_str;

CREATE INDEX IF NOT EXISTS idx_ivp_punct_de_consum_str
    ON sas_visual_analytics.informatii_verificare_publish USING btree
    (punct_de_consum_str COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;