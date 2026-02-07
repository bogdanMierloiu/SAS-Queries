# Dashboard 1 – Column Usage Map (REZULTATE_FRAUDA_PUBLISH)

This document describes which columns (data items) are used by each object in **Dashboard 1**.
Current data source for all objects: `REZULTATE_FRAUDA_PUBLISH`.

---

## 1) Control: Drop-down "Client Type"
Uses:
- `clasa_contract` (Client Type)

Purpose:
- Used as a user selection filter for client classification.

---

## 2) Control: Drop-down "Locality"
Uses:
- `localitate` (Locality)

Purpose:
- Filters data by locality.

---

## 3) Control: Selection Buttons "Service"
Uses:
- `tip_energie` (Service / Energy Type)

Purpose:
- Allows switching between services (e.g. Electricity / Gas).

---

## 4) Chart: Bar Chart "Count by County"
Uses:
- `judet` (Category / grouping)
- `Numar de cazuri` (Calculated field) = `count()`

Purpose:
- Displays number of cases per county.

Notes:
- `Numar de cazuri` is calculated at report level using `count()`.

---

## 5) Chart: "Case Distribution" (Scatter / Bubble Chart)
Uses:
- X axis:
  - `Numar de cazuri` = `count()`
- Y axis:
  - `complexitate_instalatie` (aggregation: `avg()` – average installation complexity)
- Size:
  - `procentaj` (percentage field defined in dataset or report)
- Group / Color:
  - `judet` (County)

Purpose:
- Shows distribution of cases and average installation complexity by county.

---

## 6) Map: Geographic Map (GPS points)
Uses:

### Coordinates:
- `gps_lat`
- `gps_lon`
- or derived item `geo_point` (lat/lon combined)

### Measure / Size:
- `complexitate_instalatie`

### Color / Value:
- `tip_energie_measure`

### Tooltip (data tip values):
- `partener_de_afaceri_descriere` (Business Partner)
- `tip_energie` (Service)
- `probabilitate_de_frauda` (Fraud Probability)
- `clasa_contract` (Client Type)
- GPS coordinates (`gps_lat`, `gps_lon` or `geo_point`)

### Label:
- `punct_de_consum` (Consumption Point)

Purpose:
- Displays individual consumption points on the map with risk and complexity context.

---

## 7) Table: Detail Table (bottom of dashboard)
Uses:
- `punct_de_consum`
- `partener_de_afaceri_descriere`
- `judet`
- `localitate`
- `clasa_contract`
- `complexitate_instalatie`
- `probabilitate_de_frauda`
- `sursa_complexitate`

Purpose:
- Detailed view of individual fraud cases.

---

## 8) Performance and Design Notes
- Filter controls (Client Type, Locality, Service) currently operate on the large fact table.
- Bar chart and distribution chart rely on aggregations (`count()`, `avg()`), making them good candidates for pre-aggregated overview tables.
- The map is the most expensive object due to:
  - GPS-level granularity
  - Multiple tooltip fields
  - High number of points

---

## 9) Implication for Production Architecture
This usage map can be directly used to:
- Extract filter-related columns into dedicated DIM tables
- Move aggregated visualizations to OVERVIEW fact tables
- Keep `REZULTATE_FRAUDA_PUBLISH` as a detailed FACT table used only for display (map and detail table)

