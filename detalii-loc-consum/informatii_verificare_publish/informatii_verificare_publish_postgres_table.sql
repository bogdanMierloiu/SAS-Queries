DROP TABLE IF EXISTS sas_visual_analytics.informatii_verificare_publish;

CREATE TABLE sas_visual_analytics.informatii_verificare_publish
(
    id                       BIGSERIAL PRIMARY KEY,
    punct_de_consum          BIGINT,
    punct_de_consum_str      TEXT,
    data                     DATE,
    cod_nec_1                TEXT,
    stare_loc_consum         TEXT,
    sursa_input              TEXT,
    consumator                TEXT,
    divizie                  TEXT,
    nr_doc_intocmit_pvsd_bmmm TEXT,
    nr_nota_de_constatare    TEXT,
    serie_contor             TEXT,
    cantitate                TEXT,
    um                       TEXT,
    cod_analiza              TEXT
);

CREATE INDEX IF NOT EXISTS idx_ivp_punct_de_consum
    ON sas_visual_analytics.informatii_verificare_publish(punct_de_consum);

CREATE INDEX IF NOT EXISTS idx_ivp_punct_de_consum_str
    ON sas_visual_analytics.informatii_verificare_publish(punct_de_consum_str);

TRUNCATE TABLE sas_visual_analytics.informatii_verificare_publish;

INSERT INTO sas_visual_analytics.informatii_verificare_publish (
    punct_de_consum,
    punct_de_consum_str,
    data,
    cod_nec_1,
    stare_loc_consum,
    sursa_input,
    consumator,
    divizie,
    nr_doc_intocmit_pvsd_bmmm,
    nr_nota_de_constatare,
    serie_contor,
    cantitate,
    um,
    cod_analiza
)
SELECT
    btrim(fi.nlc)::bigint AS punct_de_consum,
    fi.nlc                AS punct_de_consum_str,
	TO_DATE(fi.data::text, 'YYYY-MM-DD') AS data,
    fi.cod_nec_1,
    fi.stare_loc_consum,
    fi.sursa_input,
    fi.consumator,
    fi.divizie,
    fi.nr_doc_intocmit_pvsd_bmmm,
    fi.nr_nota_constatare AS nr_nota_de_constatare,
    fi.serie_contor,
    fi.cantitate,
    fi.um,
    fi.cod_analiza
FROM integration.field_inspections fi
WHERE btrim(fi.nlc) ~ '^[0-9]+$'
  AND EXISTS (
      SELECT 1
      FROM sas_visual_analytics.rezultate_frauda_publish r
      WHERE r.punct_de_consum = btrim(fi.nlc)::bigint
  )
ORDER BY TO_DATE(fi.data::text, 'YYYY-MM-DD') DESC;

SELECT COUNT(*)
FROM sas_visual_analytics.informatii_verificare_publish;
--350553