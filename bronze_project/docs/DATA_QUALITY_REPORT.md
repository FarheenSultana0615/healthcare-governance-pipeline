# Data Quality Report
## WHO + NDAP Healthcare Governance Pipeline
**Generated:** June 2026  
**Pipeline:** Bronze → Silver → Gold  
**Tools:** Python · dbt 1.11.8 · DuckDB 1.10.1

---

## 1. Pipeline Summary

| Metric | Value |
|---|---|
| Total dbt models | 8 |
| Total dbt tests | 31 |
| Tests passing | **31 / 31 (100%)** |
| States covered | 36 |
| Years covered | 8 |
| Total mart rows | 285 |
| Complete joins (both sources) | 141 (49.5%) |
| Incomplete joins (one source only) | 144 (50.5%) |

---

## 2. Source Data Issues Encountered

### 2.1 Corrupted State Names (NDAP Disease Dataset)
The most significant data quality issue was systematic truncation of state names in the raw Disease Incidence parquet — the **first character was stripped** from many state names, causing all downstream joins to fail.

| Raw Value | Correct Value | Fix Applied |
|---|---|---|
| `hhattisgarh` | Chhattisgarh | `LIKE '%hhattisgarh%'` mapping |
| `runachal pradesh` | Arunachal Pradesh | `LIKE '%runachal pradesh%'` mapping |
| `harkhand` | Jharkhand | `LIKE '%harkhand%'` mapping |
| `ndhra pradesh` | Andhra Pradesh | `LIKE '%ndhra pradesh%'` mapping |
| `aryana` | Haryana | `LIKE '%aryana%'` mapping |
| `disha` | Odisha | `LIKE '%disha%'` mapping |
| `imachal pradesh` | Himachal Pradesh | `LIKE '%imachal pradesh%'` mapping |
| `ujarat` | Gujarat | `LIKE '%ujarat%'` mapping |
| `ssam` | Assam | `LIKE '%ssam%'` mapping |
| `ajasthan` | Rajasthan | `LIKE '%ajasthan%'` mapping |

**Residual corruption detected in gold layer output** (partial — first character still missing):

| Observed | Likely Correct |
|---|---|
| `ikkim` | Sikkim |
| `ripura` | Tripura |
| `est bengal` | West Bengal |
| `elhi` | Delhi |
| `ttarakhand` | Uttarakhand |
| `uducherry` | Puducherry |
| `unjab` | Punjab |
| `akshadweep` | Lakshadweep |

> **Recommended fix:** extend the CASE mapping in `stg_ndap_disease.sql` to cover these additional states. Pattern is identical — single character prefix stripped.

### 2.2 Year Column Format
Raw `Year` column contained descriptive strings such as:
```
"Calendar Year (Jan - Dec), 2024"
```
**Fix:** Extracted 4-digit year with `regexp_extract(Year, '[0-9]{4}')` in both staging models.

### 2.3 Schema Mismatch Between Sources
- **Disease dataset:** grain is `State | District | Year`
- **PHC dataset:** grain is `State | Year` (no District column)

**Fix:** Aggregated disease data up to `State | Year` in `mart_disease_by_state_year` before joining. Join completeness is 49.5% — the remaining 50.5% are rows where one source has a state/year combination the other lacks.

### 2.4 Incomplete Joins
144 of 285 rows have `join_quality != 'complete'`. Root causes:
- State name residual corruption (see 2.1)
- PHC dataset does not cover all years present in the disease dataset
- Some union territories appear in disease data but not PHC data

---

## 3. Gold Layer Insights

### 3.1 Highest Burden States (API per PHC)

| State | Year | Risk Tier | API | Total PHC | API per PHC |
|---|---|---|---|---|---|
| Mizoram | 2021 | HIGH | 8.575 | 66 | 0.1299 |
| Mizoram | 2020 | HIGH | 7.360 | 68 | 0.1082 |
| Mizoram | 2019 | HIGH | 9.289 | 65 | 0.1429 |
| Andaman & Nicobar | 2019 | CRITICAL | 1.345 | 27 | 0.0498 |
| Andaman & Nicobar | 2018 | CRITICAL | 1.610 | 22 | 0.0732 |

> **Mizoram** consistently carries the highest malaria burden relative to its health infrastructure across all years in the dataset.

### 3.2 Risk Tier Distribution

| Risk Tier | State-Year Count |
|---|---|
| LOW | 87 |
| MODERATE | 44 |
| HIGH | 6 |
| CRITICAL | 2 |

### 3.3 Fastest Worsening States (YoY)

| State | Year | API Change (%) | Resource Status |
|---|---|---|---|
| Sikkim | 2021 | +204.0% | UNDER_RESOURCED |
| Tripura | 2021 | +199.7% | ADEQUATE |
| Maharashtra | 2020 | +181.8% | UNDER_RESOURCED |
| West Bengal | 2021 | +122.1% | ADEQUATE |
| Mizoram | 2019 | +96.5% | UNDER_RESOURCED |

### 3.4 Fastest Improving States (YoY)

| State | Year | API Change (%) | Resource Status |
|---|---|---|---|
| Chandigarh | 2021 | -100.0% | RECOVERING |
| Puducherry | 2021 | -100.0% | RECOVERING |
| Uttarakhand | 2020 | -97.4% | RECOVERING |
| Haryana | 2020 | -93.2% | RECOVERING |
| Punjab | 2020 | -91.6% | RECOVERING |

---

## 4. dbt Test Coverage

| Layer | Model | Tests | Status |
|---|---|---|---|
| Staging | stg_ndap_disease | not_null (facility_id, state_clean, year) | ✅ PASS |
| Staging | stg_ndap_phc | not_null (facility_id, state_clean, year) | ✅ PASS |
| Staging | stg_who_ghe | not_null (country_iso, indicator_name, year) | ✅ PASS |
| Silver | mart_disease_by_state_year | not_null, unique (state_year_key) | ✅ PASS |
| Silver | mart_phc_by_state_year | not_null, unique (state_year_key) | ✅ PASS |
| Silver | mart_india_health | not_null, accepted_values (join_quality) | ✅ PASS |
| Gold | gold_state_health_rankings | not_null, accepted_values (risk_tier) | ✅ PASS |
| Gold | gold_yoy_trends | not_null, accepted_values (trend_direction, resource_adequacy) | ✅ PASS |

**31 of 31 tests passing.**

---

## 5. Recommended Next Steps

1. **Extend state name mappings** for the 8 residual corrupted names identified above
2. **Fuzzy matching** — consider `rapidfuzz` in a Python preprocessing step for any remaining mismatches
3. **Increase join completeness** — target >80% complete rows after mapping fix
4. **Add WHO GHE join** — link global mortality indicators to Indian state-level malaria burden for cross-dataset analysis
5. **Automate report generation** — schedule pipeline + report refresh on new NDAP data releases
