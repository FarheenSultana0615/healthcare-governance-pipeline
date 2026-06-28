# Healthcare Governance Pipeline
### WHO Global Health Observatory × NDAP India — Bronze → Silver → Gold

> **Combining two government datasets with zero alignment out of the box.**  
> Corrupted state names. Mismatched schemas. Different grains. All fixed, tested, and documented.

---

## What This Project Does

This pipeline ingests messy public health data from two completely independent government sources, normalises and joins them, enforces data quality with automated tests, and produces analytical gold-layer models that answer real governance questions:

- **Which Indian states carry the highest malaria burden relative to their health infrastructure?**
- **Is malaria getting better or worse year-over-year, by state?**
- **Where is disease burden rising faster than facility capacity?**

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│  SOURCES                                            │
│  WHO Global Health Observatory  (GHE parquet)      │
│  NDAP Disease Incidence         (parquet)           │
│  NDAP PHC Facilities            (parquet)           │
└───────────────────┬─────────────────────────────────┘
                    │ Python ingestion
                    ▼
┌─────────────────────────────────────────────────────┐
│  BRONZE  (raw parquet → DuckDB)                     │
│  Stored at bronze/                                  │
└───────────────────┬─────────────────────────────────┘
                    │ dbt staging
                    ▼
┌─────────────────────────────────────────────────────┐
│  STAGING  (stg_*)                                   │
│  stg_ndap_disease   — state name normalisation      │
│  stg_ndap_phc       — facility counts, state|year   │
│  stg_who_ghe        — global mortality indicators   │
└───────────────────┬─────────────────────────────────┘
                    │ dbt silver
                    ▼
┌─────────────────────────────────────────────────────┐
│  SILVER  (mart_*)                                   │
│  mart_disease_by_state_year  — aggregated to grain  │
│  mart_phc_by_state_year      — facility counts      │
│  mart_india_health           — full outer join      │
└───────────────────┬─────────────────────────────────┘
                    │ dbt gold
                    ▼
┌─────────────────────────────────────────────────────┐
│  GOLD  (gold_*)                                     │
│  gold_state_health_rankings  — risk tiers, ranked   │
│  gold_yoy_trends             — YoY change, LAG()    │
└─────────────────────────────────────────────────────┘
```

---

## Key Data Quality Challenges Solved

| Challenge | Root Cause | Fix |
|---|---|---|
| 5,496 failing relationship rows | Corrupted state names (first char stripped) | 18-state CASE mapping in staging |
| Year cast errors | Year stored as `"Calendar Year (Jan - Dec), 2024"` | `regexp_extract(Year, '[0-9]{4}')` |
| Grain mismatch | Disease = state\|district, PHC = state\|year | Aggregate disease up to state\|year in silver |
| Alias-in-same-SELECT errors | SQL evaluation order | Intermediate `mapped` CTE pattern |
| District column missing in PHC | Source schema difference | Removed District refs, use state\|year key |

---

## Pipeline Stats

| Metric | Value |
|---|---|
| dbt models | 8 |
| dbt tests | **31 passing, 0 failing** |
| States covered | 36 |
| Years covered | 8 |
| Complete joins | 141 / 285 rows (49.5%) |

---

## Top Insights from Gold Layer

**Highest malaria burden per health centre (api_per_phc):**
- Mizoram leads every year from 2018–2021 with API as high as **9.29** on just 65 PHCs
- Andaman & Nicobar Islands reached CRITICAL tier in 2018 and 2019

**Fastest worsening states (year-over-year):**
- Sikkim: **+204%** malaria increase in 2021, classified UNDER_RESOURCED
- Tripura: **+199.7%** in 2021
- Maharashtra: **+181.8%** in 2020

**Fastest improving states:**
- Chandigarh and Puducherry: **-100%** (zero cases) by 2021
- Uttarakhand: **-97.4%** reduction in 2020

---

## How to Run

```powershell
# 1. Activate environment
& .venv\Scripts\Activate.ps1

# 2. Move into project
cd bronze_project

# 3. Build all models (bronze → silver → gold)
dbt run

# 4. Run all 31 tests
dbt test

# 5. Query results
python query_gold.py

# 6. Generate lineage docs
dbt docs generate
dbt docs serve
```

---

## Project Structure

```
WHO/
├── bronze/                          # Raw parquet files
│   ├── Disease_incidence_dataset.parquet
│   ├── PHC_Facilities_dataset.parquet
│   └── who_ghe_full.parquet
├── bronze_project/                  # dbt project
│   ├── models/
│   │   ├── staging/
│   │   │   ├── stg_ndap_disease.sql
│   │   │   ├── stg_ndap_phc.sql
│   │   │   └── stg_who_ghe.sql
│   │   ├── silver/
│   │   │   ├── mart_disease_by_state_year.sql
│   │   │   ├── mart_phc_by_state_year.sql
│   │   │   └── mart_india_health.sql
│   │   ├── gold/
│   │   │   ├── gold_state_health_rankings.sql
│   │   │   └── gold_yoy_trends.sql
│   │   └── schema.yml
│   ├── dbt_project.yml
│   └── profiles.yml
├── query_gold.py                    # Run gold queries
├── diagnose_relationships.py        # Debug join mismatches
├── DATA_QUALITY_REPORT.md           # This report
└── README.md
```

---

## Tools & Stack

| Layer | Tool |
|---|---|
| Database | DuckDB 1.10.1 |
| Transforms & Tests | dbt 1.11.8 |
| Language | Python 3.x |
| Data sources | WHO GHO API · NDAP India |
| IDE | VS Code |

---

## Data Sources

- **WHO Global Health Observatory** — [https://www.who.int/data/gho](https://www.who.int/data/gho)
- **NDAP India (National Data & Analytics Platform)** — [https://ndap.niti.gov.in](https://ndap.niti.gov.in)

---

## Author

**Farheen Sultana** · Data Modeler & Full-Stack Developer · Hyderabad, India  
Building in public. Turning messy government data into governed, testable pipelines.
