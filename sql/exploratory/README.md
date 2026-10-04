# Exploratory / QA queries

Query-uri de verificare dupa rularea `usp_refresh_dashboards_data` (sau a procedurilor `sas_1..5`).
Se ruleaza in ordine, fiecare fisier e independent.

| Fisier | Ce verifica | Ce inseamna "corect" |
|--------|-------------|----------------------|
| `00_counts_overview.sql`        | Numar randuri, NLC distincte, `loading_dttm` | Aceeasi zi/ora de incarcare pe toate; counts in linie cu NOTICE-urile |
| `01_uniqueness_duplicates.sql`  | Dubluri pe cheile naturale | `informatii_de_business` (PK) si `informatii_tehnice` (DISTINCT ON) = 0 dubluri |
| `02_client_base_coverage.sql`   | Funnel: cati clienti din baza ajung in fiecare tabela | Pierderile sa fie explicabile (join lc/contor, fereastra factura) |
| `03_referential_consistency.sql`| Leakage: puncte din afara bazei de clienti | TOATE trebuie sa returneze 0 |
| `04_data_quality.sql`           | Probabilitate in [0,1], consum > 0, campuri cheie | Fara null-uri/valori invalide neasteptate |

## Context numeric (rularea curenta)
- baza de clienti vine din `sas_visual_analytics.v_aplicare_result_base` (momentan doar `gn_pf_aplicare_result`)
- `rezultate_frauda_publish`: 136.022
- `consum_silver`: 2.269.442
- `informatii_de_business_publish`: 136.104
- `informatii_tehnice_publish`: 32.538
- `informatii_verificare_publish`: 5.049

`business` (136.104) poate fi > `rezultate` (136.022): `rezultate` cere in plus join pe `lc` +
`contor_clean` (sparte 01/02) + `tmp_ci_clean`, deci e mai restrictiv.
`informatii_verificare` este un subset din `rezultate` (sas_5 filtreaza prin `EXISTS`).
