-- Populare tabela probabilitate

CREATE TABLE integration.probabilitate AS
SELECT vstelle AS NLC,
	   ROUND(random()::numeric, 2) AS probabilitate_de_frauda
FROM integration.lc
WHERE vstelle IS NOT NULL

SELECT count(1), probabilitate_de_frauda from integration.probabilitate group by probabilitate_de_frauda

SELECT count(1) from integration.probabilitate where probabilitate_de_frauda > 0.7 -- 1.230.856

SELECT * FROM integration.probabilitate WHERE NLC = '5001656721'