# 🚀 Artemis dbt→Snowflake Demo – Workflow Bullets

## Overview
- **Goal:** Prove Artemis can optimise real dbt SQL while keeping financial reports 100% identical
- **Use Case:** Bain Capital portfolio analytics pipeline
- **Timeline:** 3 phases across ~2-3 weeks
- **Status:** Phase 1 (Input Project Setup) – IN PROGRESS

---

## 🎯 The Workflow (Visual)

```
BASELINE                  ARTEMIS                    VALIDATION
--------                  -------                    ----------
dbt project         →    Optimise SQL        →   compare_reports.py
sub-optimal SQL         Snowflake dialect       ✅ Bit-identical output
       ↓                       ↓                        ↓
run.sh              Modified models            ✓ Performance ↓
       ↓                       ↓                ✓ Cost ↓
baseline_report.csv  optimised_report.csv      ✓ Report = Same
       └─────────────────────┬─────────────────┘
                    COMPARISON (must match)
```

---

## 📋 Phase 1: Build Input Project (THIS WEEK)

### What We Have ✅
- ✅ Real dbt project (33 SQL models, 3 pipelines)
- ✅ Documented inefficiencies in each model (marked as "ISSUES FOR ARTEMIS")
- ✅ Schema definitions (sources.yml)
- ✅ Some seed data files (benchmarks, portfolios, hierarchy, date dimension)

### What We Need to Create ❌
1. **Missing Seed Files** (realistic sample data)
   - `sample_cashflows.csv` (200 rows) – cashflow transactions
   - `sample_trades.csv` (300 rows) – trade records
   - `sample_positions_daily.csv` (100 rows) – daily holdings
   - `sample_market_prices.csv` (500 rows) – security prices
   - `sample_brokers.csv` (10 rows) – broker reference
   - `sample_benchmark_returns.csv` (500 rows) – benchmark data
   - `sample_portfolio_benchmarks.csv` (10 rows) – mapping
   - `sample_valuations.csv` (100 rows) – NAV data

2. **Local Database Setup**
   - Update `profiles.yml` to use **DuckDB** (no server needed, file-based)
   - Alternative: SQLite if DuckDB issues

3. **Execution Script** (`run.sh`)
   - Install dbt + dependencies
   - Load seeds (`dbt seed`)
   - Build all models (`dbt run`)
   - Run tests (`dbt test`)
   - Export final report (`dbt run-operation export_report`)
   - Capture metrics (`capture_metrics.py`)

4. **Macro to Export Report** (`macros/export_report.sql`)
   - Query the final report table
   - Export to CSV: `output/baseline_report.csv`
   - This becomes the **golden reference**

5. **Validation Script** (`scripts/compare_reports.py`)
   - Takes 2 CSV files (baseline vs optimised)
   - Checks:
     - ✅ Same row count
     - ✅ Same columns
     - ✅ **Identical values** (no rounding drift)
   - Returns: PASS/FAIL

6. **Documentation**
   - `SETUP_AND_RUN.md` – How to execute locally
   - `DEMO_WORKFLOW_TEAM.md` – Full detailed workflow (already created)

---

## 📋 Phase 2: Hand Off to Artemis

### What Artemis Receives
- Complete dbt project with all models
- Sample data (seeds)
- `run.sh` script
- `baseline_report.csv` – golden reference
- `baseline_metrics.json` – performance baseline
- Brief: "Optimise SQL, keep report identical"

### Artemis Does This
- Resolves full dbt DAG (model lineage)
- Identifies inefficiencies (marked in comments)
- Rewrites SQL to Snowflake best practices:
  - Remove unnecessary DISTINCT
  - Push filters upstream
  - Collapse nested CTEs
  - Optimise window functions
  - Simplify joins
- Ensures all dbt tests still pass
- Returns: Optimised `models/` directory + new report

### Constraints (Non-negotiable)
- ❌ DO NOT change column names
- ❌ DO NOT change report structure
- ❌ DO NOT change numeric values
- ✅ DO optimise SQL syntax
- ✅ DO rewrite for Snowflake
- ✅ DO simplify inefficient patterns

---

## 📋 Phase 3: Validation & Measurement

### Run Comparison
```bash
python scripts/compare_reports.py \
    output/baseline_report.csv \
    output/optimised_report.csv
```

### Success Criteria
- ✅ Row counts identical
- ✅ Column names identical
- ✅ All numeric values identical (bit-for-bit)
- ✅ All dbt tests pass (100%)
- ✅ No errors during execution

### Metrics to Capture
- dbt run time: **Before** vs **After** (e.g., 12.5s → 8.2s = **1.52x faster**)
- Row counts per model: Must match
- Financial aggregates: Sum, avg, count (must match)
- Test results: All pass
- Database size: Optional (for cost estimation)

---

## 🎯 Deliverables by Phase

### Phase 1 Deliverables
- [ ] Complete seed files (all 8 CSVs)
- [ ] `profiles.yml` configured for DuckDB
- [ ] `run.sh` script (fully working)
- [ ] `macros/export_report.sql` (exports final report)
- [ ] `scripts/compare_reports.py` (validation script)
- [ ] `scripts/capture_metrics.py` (metrics capture)
- [ ] `output/baseline_report.csv` (golden reference)
- [ ] `output/baseline_metrics.json` (baseline performance)
- [ ] `SETUP_AND_RUN.md` (instructions)

### Phase 2 Deliverables (from Artemis)
- [ ] Optimised `models/` directory
- [ ] `output/optimised_report.csv`
- [ ] Optimisation notes (what changed in each model)

### Phase 3 Deliverables
- [ ] Comparison report (baseline vs optimised)
- [ ] Validation results (PASS/FAIL)
- [ ] Metrics comparison (performance, costs)
- [ ] Demo-ready summary slide

---

## 🏗️ Project Structure (End State)

```
sample-dbt-project/
│
├── models/                          # dbt models (will be optimised)
│   ├── pipeline_a/
│   │   ├── staging/
│   │   └── marts/
│   ├── pipeline_b/
│   ├── pipeline_c/
│   └── schema.yml
│
├── seeds/                           # Sample data CSVs
│   ├── dim_date.csv ✅
│   ├── sample_benchmarks.csv ✅
│   ├── sample_cashflows.csv ❌ (TODO)
│   ├── sample_trades.csv ❌ (TODO)
│   ├── sample_positions_daily.csv ❌ (TODO)
│   ├── sample_market_prices.csv ❌ (TODO)
│   ├── sample_brokers.csv ❌ (TODO)
│   ├── sample_benchmark_returns.csv ❌ (TODO)
│   ├── sample_portfolio_benchmarks.csv ❌ (TODO)
│   └── sample_valuations.csv ❌ (TODO)
│
├── macros/
│   └── export_report.sql ❌ (TODO)
│
├── scripts/
│   ├── compare_reports.py ❌ (TODO)
│   └── capture_metrics.py ❌ (TODO)
│
├── output/
│   ├── baseline_report.csv ❌ (TODO – will be generated)
│   └── baseline_metrics.json ❌ (TODO – will be generated)
│
├── run.sh ❌ (TODO)
├── profiles.yml (update needed)
├── dbt_project.yml ✅
│
├── DEMO_WORKFLOW_TEAM.md ✅ (detailed guide)
├── DEMO_WORKFLOW_BULLETS.md ✅ (this file)
└── SETUP_AND_RUN.md ❌ (TODO)
```

---

## ⚡ Quick Checklist (Copy-Paste for Jira/Notion)

### Phase 1 Tasks
- [ ] Create 8 seed CSV files with realistic data
- [ ] Update `profiles.yml` for DuckDB
- [ ] Write `run.sh` execution script
- [ ] Create `macros/export_report.sql`
- [ ] Write `scripts/compare_reports.py` validation
- [ ] Write `scripts/capture_metrics.py` metrics capture
- [ ] Execute `bash run.sh` locally
- [ ] Verify `output/baseline_report.csv` exists
- [ ] Verify `output/baseline_metrics.json` exists
- [ ] Document in `SETUP_AND_RUN.md`

### Phase 2 Tasks
- [ ] Package project for Artemis (zip or git push)
- [ ] Send brief: "Optimise SQL, keep report identical"
- [ ] Artemis returns optimised models
- [ ] Artemis returns `output/optimised_report.csv`

### Phase 3 Tasks
- [ ] Run: `python compare_reports.py baseline_report.csv optimised_report.csv`
- [ ] Verify: Reports are identical ✅
- [ ] Capture metrics comparison
- [ ] Write demo summary

---

## 🔑 Key Rules (Golden Rules)

1. **Report is Sacred:** Even 1 changed digit = FAIL
2. **SQL is Flexible:** Rewrite, refactor, optimize freely
3. **Tests are Required:** All dbt tests must pass both before & after
4. **Validation is Automated:** compare_reports.py must return PASS
5. **No Snowflake Yet:** Use DuckDB for demo (easy to run locally)

---

## 📞 Roles & Responsibilities

| Role | Responsibility |
|------|-----------------|
| **Claude + Dev Team** | Build Phase 1 (seeds, scripts, baseline) |
| **Artemis Team** | Phase 2 (optimise SQL models) |
| **QA/Validation** | Phase 3 (run comparison, measure improvements) |
| **Product/Sales** | Phase 4 (demo to Bain Capital) |

---

## 🎬 Demo Narrative (Once Complete)

> "We took a real Bain Capital dbt project with known SQL inefficiencies.
>
> Artemis analysed the full pipeline, rewrote the SQL for Snowflake best practices, and optimised joins, aggregations, and CTEs.
>
> The result? **Identical financial reports** (bit-for-bit), but:
> - ✅ SQL is faster (1.52x speedup)
> - ✅ Snowflake credits are lower
> - ✅ Code is cleaner and easier to maintain
>
> This is how Artemis keeps your data pipeline safe while making it faster and cheaper."

---

## 📊 Expected Results

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| dbt runtime | 12.5s | 8.2s | 1.52x faster |
| Snowflake credits | (estimate) 5.2 | (estimate) 3.1 | 40% reduction |
| Report rows | 420 | 420 | ✅ Identical |
| Report columns | 15 | 15 | ✅ Identical |
| Report values | Sum=$1.5B | Sum=$1.5B | ✅ Identical |
| dbt tests | 18/18 ✅ | 18/18 ✅ | ✅ All pass |

---

**Status:** Phase 1 – IN PROGRESS
**Last Updated:** 2026-01-24
**Owner:** Claude + Team
