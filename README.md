# SAS Visual Analytics – Refresh Date (NTL)

Repository cu scripturile SQL si de orchestrare pentru alimentarea zilnica a
dashboard-urilor din **SAS Visual Analytics**, pe baza datelor din PostgreSQL
(schema `sas_visual_analytics`).

---

## Ce face proiectul

In fiecare luna, un scheduler Linux (`at`) porneste secvential 5 joburi. Fiecare
job apeleaza o procedura PostgreSQL care reimprospateaza o tabela `*_publish`.
Dashboard-urile din SAS Visual Analytics citesc apoi aceste tabele.

```
update_ntl.sh  ->  Linux `at`  ->  start_sas_1..5  ->  proceduri sas_1..5  ->  tabele *_publish  ->  SAS VA
```

> Diagrama completa: [`docs/Flux_Refresh_SAS_Visual_Analytics.pptx`](docs/Flux_Refresh_SAS_Visual_Analytics.pptx)

---

## Structura repository-ului

```
.
├── README.md                     Acest ghid
├── update_ntl.sh                 Script de planificare: programeaza joburile cu `at`
├── sql/
│   ├── ddl/                      Definitii de tabele (CREATE TABLE / view-uri)
│   ├── procedures/              Procedurile de refresh
│   └── exploratory/             Query-uri de verificare (QA) dupa refresh
├── docs/                         Documentatie + prezentari (.docx, .pptx)
└── packages/                    Pachet export SAS (.spk)
```

### `update_ntl.sh`
Programeaza cele 5 joburi la ore fixe prin comanda `at`:

| Ora   | Job             | Reimprospateaza                  |
|-------|-----------------|----------------------------------|
| 02:00 | `start_sas_1`   | `rezultate_frauda_publish`       |
| 04:00 | `start_sas_2`   | `consum_silver`                  |
| 07:00 | `start_sas_3`   | `informatii_de_business_publish` |
| 09:00 | `start_sas_4`   | `informatii_tehnice_publish`     |
| 09:30 | `start_sas_5`   | `informatii_verificare_publish`  |

### `sql/ddl/`
Structura tabelelor si a view-ului sursa:
- `aplicare_result_base.sql` – baza de clienti (`v_aplicare_result_base`)
- `rezultate_frauda_publish.sql`
- `consum_silver.sql`
- `informatii_de_business_publish.sql`
- `informatii_tehnice_publish.sql`
- `informatii_verificare_publish.sql`

### `sql/procedures/`
- `usp_refresh_dashboards_data.sql` – **orchestratorul**: apeleaza secvential
  procedurile `sas_1..5` (acelasi rezultat ca rularea celor 5 joburi).
- `cazuri-frauda-general-overview/` – `sas_1_usp_refresh_rezultate_frauda_publish`
- `detalii-loc-consum/` – procedurile `sas_2..5`

### `sql/exploratory/`
Query-uri QA de rulat dupa refresh (counts, dubluri, acoperire, consistenta
referentiala, calitatea datelor). Detalii in
[`sql/exploratory/README.md`](sql/exploratory/README.md).

### `docs/` si `packages/`
- `docs/` – prezentari si documentatie (`.pptx`, `.docx`) + diagrama de flux.
- `packages/` – pachet de transport SAS (`.spk`).

---

## Cum se ruleaza

**Refresh complet, manual (recomandat pentru test):**
```sql
CALL sas_visual_analytics.usp_refresh_dashboards_data();
```

**Refresh automat, zilnic (pe serverul SAS/Linux):**
```bash
bash update_ntl.sh      # programeaza joburile cu `at`
at -l                   # verifica joburile programate
```

**Verificare dupa refresh:**
```bash
# ruleaza in ordine fisierele din sql/exploratory/ (00 -> 04)
```

---

## Volume orientative (rulare curenta)

| Tabela                            | Randuri     |
|-----------------------------------|-------------|
| `rezultate_frauda_publish`        | 136.022     |
| `consum_silver`                   | 2.269.442   |
| `informatii_de_business_publish`  | 136.104     |
| `informatii_tehnice_publish`      | 32.538      |
| `informatii_verificare_publish`   | 5.049       |

---

## Flux de refresh (schema text)

```
            REFRESH DATE SAS VISUAL ANALYTICS

              Script principal de planificare
                         |
                         v
              Linux Scheduler - comanda `at`
                         |
       +-----------------+------------------+------------------+------------------+
       |                 |                  |                  |                  |
       v                 v                  v                  v                  v
     02:00             04:00              07:00              09:00              09:30
       |                 |                  |                  |                  |
       v                 v                  v                  v                  v
  start_sas_1       start_sas_2        start_sas_3        start_sas_4        start_sas_5
       |                 |                  |                  |                  |
       v                 v                  v                  v                  v
 rezultate_frauda     consum_silver      informatii         informatii         informatii
    _publish                              business            tehnice           verificare
                                           _publish           _publish           _publish
       |                 |                  |                  |                  |
       +-----------------+------------------+------------------+------------------+
                                            |
                                            v
                              PostgreSQL - sas_visual_analytics
                                            |
                                            v
                                  SAS Visual Analytics
                                      Dashboards
```
