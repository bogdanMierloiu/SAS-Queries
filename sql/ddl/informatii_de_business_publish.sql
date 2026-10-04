-- Table: sas_visual_analytics.informatii_de_business_publish

-- DROP TABLE IF EXISTS sas_visual_analytics.informatii_de_business_publish;

CREATE TABLE IF NOT EXISTS sas_visual_analytics.informatii_de_business_publish
(
    punct_de_consum bigint NOT NULL,
    punct_de_consum_str text COLLATE pg_catalog."default",
    numar_instalatie text COLLATE pg_catalog."default",
    partener_de_afaceri text COLLATE pg_catalog."default",
    name text COLLATE pg_catalog."default",
    reg_number text COLLATE pg_catalog."default",
    cif_number text COLLATE pg_catalog."default",
    clasa_contract text COLLATE pg_catalog."default",
    categorie_tarif text COLLATE pg_catalog."default",
    tip_facturare text COLLATE pg_catalog."default",
    invoicing_party text COLLATE pg_catalog."default",
    nivel_tensiune text COLLATE pg_catalog."default",
    urban_rural text COLLATE pg_catalog."default",
    judet text COLLATE pg_catalog."default",
    localitate text COLLATE pg_catalog."default",
    strada text COLLATE pg_catalog."default",
    subregiune text COLLATE pg_catalog."default",
    region text COLLATE pg_catalog."default",
    region_name text COLLATE pg_catalog."default",
    city text COLLATE pg_catalog."default",
    ind_sector text COLLATE pg_catalog."default",
    ind_sector_desc text COLLATE pg_catalog."default",
    loading_dttm timestamp(0) without time zone,
    CONSTRAINT informatii_de_business_publish_pkey PRIMARY KEY (punct_de_consum)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS sas_visual_analytics.informatii_de_business_publish
    OWNER to pgadmin;
-- Index: idx_idbp_judet

-- DROP INDEX IF EXISTS sas_visual_analytics.idx_idbp_judet;

CREATE INDEX IF NOT EXISTS idx_idbp_judet
    ON sas_visual_analytics.informatii_de_business_publish USING btree
    (judet COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: idx_idbp_localitate

-- DROP INDEX IF EXISTS sas_visual_analytics.idx_idbp_localitate;

CREATE INDEX IF NOT EXISTS idx_idbp_localitate
    ON sas_visual_analytics.informatii_de_business_publish USING btree
    (localitate COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: idx_idbp_partner

-- DROP INDEX IF EXISTS sas_visual_analytics.idx_idbp_partner;

CREATE INDEX IF NOT EXISTS idx_idbp_partner
    ON sas_visual_analytics.informatii_de_business_publish USING btree
    (partener_de_afaceri COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: idx_idbp_pdc

-- DROP INDEX IF EXISTS sas_visual_analytics.idx_idbp_pdc;

CREATE INDEX IF NOT EXISTS idx_idbp_pdc
    ON sas_visual_analytics.informatii_de_business_publish USING btree
    (punct_de_consum ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: idx_idbp_pdc_str

-- DROP INDEX IF EXISTS sas_visual_analytics.idx_idbp_pdc_str;

CREATE INDEX IF NOT EXISTS idx_idbp_pdc_str
    ON sas_visual_analytics.informatii_de_business_publish USING btree
    (punct_de_consum_str COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;