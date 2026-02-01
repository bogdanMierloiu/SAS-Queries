DROP TABLE IF EXISTS sas_visual_analytics.complexitate_instalatie;

CREATE TABLE sas_visual_analytics.complexitate_instalatie (
    devloc TEXT NOT NULL,
    complexitate_instalatie INT,
    sursa_complexitate TEXT CHECK (sursa_complexitate IN ('CONTOR', 'TRANSFORMATOR')),
    PRIMARY KEY (devloc, sursa_complexitate)
);


-- Index pe devloc pentru că va fi filtrat frecvent
CREATE INDEX IF NOT EXISTS idx_complexitate_devloc
    ON sas_visual_analytics.complexitate_instalatie (devloc);

-- Index pe complexitate pentru agregări/filtrări
CREATE INDEX IF NOT EXISTS idx_complexitate_val
    ON sas_visual_analytics.complexitate_instalatie (complexitate_instalatie);

-- Index pe sursa_complexitate pentru filtrări rapide între tipuri
CREATE INDEX IF NOT EXISTS idx_complexitate_sursa
    ON sas_visual_analytics.complexitate_instalatie (sursa_complexitate);


TRUNCATE TABLE sas_visual_analytics.complexitate_instalatie;


INSERT INTO sas_visual_analytics.complexitate_instalatie (
    devloc, complexitate_instalatie, sursa_complexitate
)
-- sursa 1: contor_clean
SELECT devloc,
	   complexitate_instalatie AS complexitate_instalatie,
	   'CONTOR' AS sursa_complexitate
 FROM sas_visual_analytics.contor_clean
WHERE complexitate_instalatie IS NOT NULL

UNION ALL

-- sursa 2: transformator_clean
SELECT devloc,
	   complexitate_instalatie AS complexitate_instalatie,
	  'TRANSFORMATOR' AS sursa_complexitate
FROM sas_visual_analytics.transformator_clean
WHERE complexitate_instalatie IS NOT NULL;


-- SELECT * FROM sas_visual_analytics.complexitate_instalatie where devloc = '7000921061';