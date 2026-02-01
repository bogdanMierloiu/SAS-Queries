DROP TABLE IF EXISTS sas_visual_analytics.tehnic_contor_clean;

CREATE TABLE IF NOT EXISTS sas_visual_analytics.tehnic_contor_clean (
    devloc TEXT PRIMARY KEY,
    equnr TEXT,
    sparte TEXT,
    matnr TEXT,
    matnr_desc TEXT,
    sernr TEXT,
    gertyptxtl TEXT,
    ami_am_active TEXT,
    datab_date DATE,
    datbi_date DATE
);

CREATE INDEX IF NOT EXISTS idx_tehnic_contor_clean_equnr ON sas_visual_analytics.tehnic_contor_clean(equnr);
CREATE INDEX IF NOT EXISTS idx_tehnic_contor_clean_sparte ON sas_visual_analytics.tehnic_contor_clean(sparte);
CREATE INDEX IF NOT EXISTS idx_tehnic_contor_clean_datab_datbi ON sas_visual_analytics.tehnic_contor_clean(datab_date, datbi_date);

TRUNCATE TABLE sas_visual_analytics.tehnic_contor_clean;

INSERT INTO sas_visual_analytics.tehnic_contor_clean (
    devloc, equnr, sparte, matnr, matnr_desc, sernr, gertyptxtl, ami_am_active, datab_date, datbi_date
)
SELECT DISTINCT ON (c.devloc)
    c.devloc,
    c.equnr,
    c.sparte,
    c.matnr,
    c.matnr_desc,
    c.sernr,
    c.gertyptxtl,
    c.ami_am_active,
    TO_DATE(c.datab::text, 'YYYYMMDD') AS datab_date,
    TO_DATE(c.datbi::text, 'YYYYMMDD') AS datbi_date
FROM integration.contor c
WHERE c.devloc IS NOT NULL
  AND c.datab IS NOT NULL
  AND c.datbi IS NOT NULL
  AND CURRENT_DATE BETWEEN TO_DATE(c.datab::text, 'YYYYMMDD')
                        AND TO_DATE(c.datbi::text, 'YYYYMMDD');


-- SELECT COUNT(*) FROM sas_visual_analytics.tehnic_contor_clean
-- 2.829.045

DROP TABLE IF EXISTS sas_visual_analytics.informatii_tehnice_publish;

CREATE TABLE sas_visual_analytics.informatii_tehnice_publish (
    punct_de_consum BIGINT PRIMARY KEY,
    punct_de_consum_str TEXT,
    loc_dispozitiv TEXT,
    adresa TEXT,
    gps_latitudine TEXT,
    gps_longitudine TEXT,
    tip_punct_consum_cod TEXT,
    tip_punct_consum_desc TEXT,
    nr_persoane INT,
    instalatie TEXT,
    divizie TEXT,
    divizie_desc TEXT,
    categorie_tarif TEXT,
    categorie_tarif_desc TEXT,
    grila_cod TEXT,
    grid_name TEXT,
    nivel_retea TEXT,
    scenariu_furnizare_desc TEXT,
    nr_echipament TEXT,
    material TEXT,
    material_descriere TEXT,
    nr_serie TEXT,
    tip_contor TEXT,
    valabil_de_la DATE,
    valabil_pana_la DATE,
    am_activ_inactiv TEXT
);


CREATE INDEX IF NOT EXISTS idx_itp_punct_de_consum ON sas_visual_analytics.informatii_tehnice_publish(punct_de_consum);
CREATE INDEX IF NOT EXISTS idx_itp_punct_de_consum_str ON sas_visual_analytics.informatii_tehnice_publish(punct_de_consum_str);


TRUNCATE TABLE sas_visual_analytics.informatii_tehnice_publish;

INSERT INTO sas_visual_analytics.informatii_tehnice_publish
(
    punct_de_consum,
    punct_de_consum_str,
    loc_dispozitiv,
    adresa,
    gps_latitudine,
    gps_longitudine,
    tip_punct_consum_cod,
    tip_punct_consum_desc,
    nr_persoane,
    instalatie,
    divizie,
    divizie_desc,
    categorie_tarif,
    categorie_tarif_desc,
    grila_cod,
    grid_name,
    nivel_retea,
    scenariu_furnizare_desc,
    nr_echipament,
    material,
    material_descriere,
    nr_serie,
    tip_contor,
    valabil_de_la,
    valabil_pana_la,
    am_activ_inactiv
)
SELECT
    b.punct_de_consum,
    b.punct_de_consum::text AS punct_de_consum_str,
    lc.devloc AS loc_dispozitiv,
    lc.address AS adresa,
    lc.gps_lat AS gps_latitudine,
    lc.gps_lon AS gps_longitudine,
    lc.vbsart AS tip_punct_consum_cod,
    lc.vbsart_desc AS tip_punct_consum_desc,
    lc.anzpers::INT AS nr_persoane,
    inst.anlage AS instalatie,
    inst.sparte AS divizie,
    inst.sparte_desc AS divizie_desc,
    inst.tariftyp AS categorie_tarif,
    inst.tariftyp_desc AS categorie_tarif_desc,
    inst.grid_id AS grila_cod,
    inst.grid_name,
    inst.grid_level AS nivel_retea,
    inst.scenario_desc AS scenariu_furnizare_desc,
    cnt.equnr AS nr_echipament,
    cnt.matnr AS material,
    cnt.matnr_desc AS material_descriere,
    cnt.sernr AS nr_serie,
    cnt.gertyptxtl AS tip_contor,
    cnt.datab_date AS valabil_de_la,
    cnt.datbi_date AS valabil_pana_la,
    COALESCE(cnt.ami_am_active, 'N/A') AS am_activ_inactiv
FROM sas_visual_analytics.business_bill_39 b
INNER JOIN integration.lc lc
    ON b.punct_de_consum_str = lc.vstelle
INNER JOIN integration.instalatie inst
    ON b.numar_instalatie = inst.anlage
INNER JOIN sas_visual_analytics.tehnic_contor_clean cnt
    ON cnt.devloc = lc.devloc;




SELECT COUNT(*) FROM sas_visual_analytics.informatii_tehnice_publish
-- 3.436.500