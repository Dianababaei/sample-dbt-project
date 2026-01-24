# 🚀 Artemis dbt→Snowflake Optimisation Demo Workflow

**Objective:** Demonstrate Artemis can optimise a real dbt project with **zero change to financial reports**

**Client Example:** Bain Capital Portfolio Analytics
**Repository:** `sample-dbt-project`
**Status:** Ready for Phase 1 (Input Project Setup)

---

## 📊 The Big Picture

```
BASELINE                    ARTEMIS                      VALIDATION
---------                   -------                      ----------

dbt project          →   Optimise SQL          →   compare_reports.py
(sub-optimal SQL)        (Snowflake dialect)       ✅ Bit-identical output
       ↓                        ↓                          ↓
run.sh                   Modified models           ✓ ROI: Perf ↓, Cost ↓
       ↓                        ↓                       ✓ Safety: Report = Same
baseline_report.csv   optimised_report.csv
       ↓                        ↓
       └────────────────────────┘
                    COMPARISON
              (must be identical)
```

**Result:** Shows Artemis delivers:
- ✅ Faster SQL execution
- ✅ Lower Snowflake credits
- ✅ **Identical business outputs** (financial reports unchanged)

---

## 🎯 What Each Phase Does

| Phase | What | Who | Output |
|-------|------|-----|--------|
| **Phase 1: Build Input** | Create example dbt project with sample data | Claude + Team | Complete, runnable project |
| **Phase 2: Hand Off** | Give to Artemis with baseline metrics | Project Lead | Optimised SQL models |
| **Phase 3: Validate** | Compare reports, measure improvements | Validation Engineer | Pass/fail with metrics |
| **Phase 4: Demo** | Show results to stakeholders | Product Lead | Proof of concept complete |

---

## 📋 Phase 1: Build Input Project (THIS WEEK)

### What We Already Have ✅

- **Real dbt Models** (33 SQL files across 3 pipelines)
  - Pipeline A: Simple (cashflow analytics)
  - Pipeline B: Medium (trade analytics)
  - Pipeline C: Complex (portfolio performance)

- **Documented Inefficiencies**
  - Each model has comments marking `ISSUES FOR ARTEMIS TO OPTIMIZE`
  - Real but known sub-optimal patterns

- **Sample Data Seeds**
  - `sample_portfolios.csv`
  - `sample_benchmarks.csv`
  - `sample_fund_hierarchy.csv`
  - `dim_date.csv`
  - `sample_securities.csv`

### What We Still Need ❌

#### ✅ Task 1: Create Missing Seed Files

**Files needed:**

1. **seeds/sample_cashflows.csv** (~150-200 rows)
   ```csv
   cashflow_id,portfolio_id,cashflow_type,cashflow_date,amount,currency,created_at,updated_at
   1,1,CONTRIBUTION,2020-01-15,1000000.00,USD,2020-01-15T10:00:00Z,2020-01-15T10:00:00Z
   2,1,DISTRIBUTION,2020-03-20,500000.00,USD,2020-03-20T14:30:00Z,2020-03-20T14:30:00Z
   ...
   ```

2. **seeds/sample_trades.csv** (~300-400 rows)
   ```csv
   trade_id,portfolio_id,security_id,trade_date,trade_type,quantity,price,net_amount,broker_id,created_at
   1,1,101,2020-02-01,BUY,1000,50.00,50000.00,1,2020-02-01T09:30:00Z
   ...
   ```

3. **seeds/sample_positions_daily.csv** (~100-150 rows)
   ```csv
   position_id,portfolio_id,security_id,position_date,quantity,market_value_usd,created_at
   1,1,101,2024-12-31,1000,55000.00,2024-12-31T17:00:00Z
   ...
   ```

4. **seeds/sample_market_prices.csv** (~500-600 rows)
   ```csv
   security_id,price_date,close_price,volume,created_at
   101,2020-01-01,50.00,1000000,2020-01-01T17:00:00Z
   ...
   ```

5. **seeds/sample_brokers.csv** (~5-10 rows)
   ```csv
   broker_id,broker_name,created_at
   1,Goldman Sachs,2020-01-01T00:00:00Z
   ...
   ```

6. **seeds/sample_benchmark_returns.csv** (~500-600 rows)
   ```csv
   benchmark_id,return_date,daily_return,created_at
   1,2020-01-01,0.005,2020-01-01T17:00:00Z
   ...
   ```

7. **seeds/sample_portfolio_benchmarks.csv** (~10 rows)
   ```csv
   portfolio_id,benchmark_id,is_primary,created_at
   1,1,true,2020-01-01T00:00:00Z
   ...
   ```

8. **seeds/sample_valuations.csv** (~100-150 rows)
   ```csv
   valuation_id,portfolio_id,valuation_date,nav,nav_usd,created_at
   1,1,2020-01-31,5000000.00,5000000.00,2020-01-31T17:00:00Z
   ...
   ```

**Why:** dbt needs actual data to build tables. These create the RAW layer that staging/mart models transform.

---

#### ✅ Task 2: Set Up Local Database

**Option A: DuckDB (Recommended for demo)**
- Zero setup
- Files-based (no server needed)
- Fast for this data size
- Simple for CI/CD

**Option B: SQLite**
- Also zero setup
- Slower than DuckDB
- Good fallback

**Option C: Local Snowflake** (skip for now)
- Requires credentials
- Overkill for demo
- Use later in production

**Action:** Update `profiles.yml` to use DuckDB:

```yaml
bain_capital:
  target: dev_local
  outputs:
    dev_local:
      type: duckdb
      path: ./bain_analytics.duckdb
      schema: analytics
      threads: 4
```

---

#### ✅ Task 3: Create Execution Script (run.sh)

```bash
#!/bin/bash
set -e

echo "🚀 Starting dbt pipeline..."
echo "=================================================="

# Install dependencies
echo "📦 Installing dbt packages..."
dbt deps

# Seed data into local database
echo "📊 Loading seed data..."
dbt seed --full-refresh

# Build all models
echo "🏗️  Building dbt models..."
dbt run

# Run validation tests
echo "✅ Running dbt tests..."
dbt test

# Generate documentation
echo "📖 Generating docs..."
dbt docs generate

# Export baseline report
echo "💾 Exporting baseline report..."
mkdir -p output
dbt run-operation export_report --args '{"output_dir": "output"}'

# Capture metrics
echo "📈 Capturing baseline metrics..."
python scripts/capture_metrics.py > output/baseline_metrics.json

echo "=================================================="
echo "✅ Pipeline complete!"
echo ""
echo "📁 Outputs:"
echo "   - output/baseline_report.csv     (Main report)"
echo "   - output/baseline_metrics.json   (Performance metrics)"
echo ""
```

**Also needed:** `scripts/capture_metrics.py`

```python
import json
import os
from datetime import datetime

metrics = {
    "timestamp": datetime.now().isoformat(),
    "database": "duckdb",
    "dbt_version": os.popen("dbt --version").read().strip(),
    "models": {
        "pipeline_a": {
            "stg_cashflows": os.popen("select count(*) from raw.cashflows").read().strip(),
            "fact_cashflow_summary": os.popen("select count(*) from pipeline_a.fact_cashflow_summary").read().strip(),
            "report_monthly_cashflows": os.popen("select count(*) from pipeline_a.report_monthly_cashflows").read().strip(),
        }
    }
}

print(json.dumps(metrics, indent=2))
```

---

#### ✅ Task 4: Create Macro to Export Report

**File:** `macros/export_report.sql`

```sql
{% macro export_report(output_dir) %}
    {% set results = run_query(
        "SELECT * FROM " ~ target.schema ~ ".report_monthly_cashflows"
    ) %}

    {% if execute %}
        {% set rows = results.rows %}
        {% set columns = results.columns | map(attribute="name") | list %}

        {% set output_path = output_dir ~ "/baseline_report.csv" %}

        -- Write CSV header
        {% set header_line = columns | join(",") %}

        -- Write data rows
        {% for row in rows %}
            {{ log(row) }}
        {% endfor %}
    {% endif %}
{% endmacro %}
```

---

#### ✅ Task 5: Create Validation Script (compare_reports.py)

**File:** `scripts/compare_reports.py`

```python
#!/usr/bin/env python3
import pandas as pd
import sys
import json
from pathlib import Path

def compare_reports(baseline_path, optimised_path, output_path=None):
    """
    Compare two CSV reports and validate they are identical.

    Returns:
        True if reports match, False otherwise
    """
    print("=" * 60)
    print("📊 REPORT COMPARISON")
    print("=" * 60)

    # Load files
    try:
        baseline = pd.read_csv(baseline_path)
        optimised = pd.read_csv(optimised_path)
    except FileNotFoundError as e:
        print(f"❌ Error: {e}")
        return False

    # Check 1: Dimensions
    print(f"\n✓ Baseline shape:  {baseline.shape}")
    print(f"✓ Optimised shape: {optimised.shape}")

    if baseline.shape != optimised.shape:
        print("❌ FAIL: Shape mismatch!")
        return False

    # Check 2: Columns
    baseline_cols = list(baseline.columns)
    optimised_cols = list(optimised.columns)

    if baseline_cols != optimised_cols:
        print(f"❌ FAIL: Column mismatch!")
        print(f"   Baseline:  {baseline_cols}")
        print(f"   Optimised: {optimised_cols}")
        return False

    # Check 3: Values (exact match)
    if not baseline.equals(optimised):
        print("❌ FAIL: Values differ!")
        # Show first few diffs
        mask = baseline != optimised
        diffs = mask.sum(axis=1)
        print(f"   Rows with differences: {(diffs > 0).sum()}")
        if (diffs > 0).sum() > 0:
            print(f"   First mismatch:\n{baseline[mask.any(axis=1)].head()}")
        return False

    # All checks pass
    print("\n" + "=" * 60)
    print("✅ SUCCESS: Reports are identical!")
    print("=" * 60)

    # Save comparison result
    if output_path:
        result = {
            "status": "PASS",
            "baseline_rows": len(baseline),
            "optimised_rows": len(optimised),
            "columns_match": len(baseline_cols),
            "financial_metrics": {
                "total_cashflow_baseline": baseline.select_dtypes("number").sum().sum() if len(baseline) > 0 else 0,
            }
        }
        with open(output_path, 'w') as f:
            json.dump(result, f, indent=2)

    return True

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python compare_reports.py <baseline.csv> <optimised.csv>")
        sys.exit(1)

    baseline = sys.argv[1]
    optimised = sys.argv[2]
    output = sys.argv[3] if len(sys.argv) > 3 else None

    success = compare_reports(baseline, optimised, output)
    sys.exit(0 if success else 1)
```

---

### ✅ Task 6: Create README for Execution

**File:** `SETUP_AND_RUN.md`

```markdown
# How to Build and Run the Example dbt Project

## Quick Start

```bash
# 1. Install dependencies
pip install dbt-duckdb dbt-utils

# 2. Run the full pipeline
bash run.sh

# 3. Output will be in:
# - output/baseline_report.csv
# - output/baseline_metrics.json
```

## What Gets Created

### Database Schema

```
bain_analytics.duckdb
├── RAW (source data from seeds)
├── pipeline_a
│   ├── cashflows (stg)
│   ├── portfolios (stg)
│   ├── fact_cashflow_summary
│   └── report_monthly_cashflows
├── pipeline_b
│   ├── trades (stg)
│   ├── market_prices (stg)
│   ├── fact_portfolio_positions
│   └── report_trading_performance
└── pipeline_c
    ├── positions_daily (stg)
    ├── benchmarks (stg)
    ├── fact_portfolio_performance
    └── report_ic_dashboard
```

### Report Output

**baseline_report.csv** - Final report from `report_monthly_cashflows`

```csv
portfolio_id,portfolio_name,cashflow_month,contributions,distributions,...
1,Tech Fund,2020-01-31,1000000.00,0.00,...
```

## Validation

```bash
# After Artemis optimises and returns new project:
python scripts/compare_reports.py output/baseline_report.csv output/optimised_report.csv
```

**Expected output:**
```
✅ SUCCESS: Reports are identical!
```

## Metrics

**baseline_metrics.json** captures:
- dbt run time
- Row counts per model
- Financial aggregates (sums, averages)

## Next Steps

1. Run `bash run.sh` ← generates baseline
2. Send project to Artemis
3. Artemis returns optimised `models/` directory
4. Run `bash run.sh` again (new run uses optimised models)
5. Run `python compare_reports.py baseline_report.csv optimised_report.csv`

---
```

---

## 📋 Phase 2: Hand Off to Artemis

### What to Include

```
sample-dbt-project/
├── models/               ← All .sql files
├── seeds/               ← Sample data (.csv)
├── dbt_project.yml      ← Config
├── profiles.yml         ← Database config (DuckDB)
├── run.sh               ← Execution script
├── scripts/
│   ├── capture_metrics.py
│   └── compare_reports.py
├── output/
│   ├── baseline_report.csv          ← Golden reference
│   └── baseline_metrics.json
└── README.md            ← Instructions
```

### Brief for Artemis

> **Objective:** Optimise the SQL models in `models/` for Snowflake while preserving exact report outputs.
>
> **Constraints:**
> - ❌ Do NOT change column names or report structure
> - ❌ Do NOT change numeric values (even by rounding)
> - ❌ All dbt tests must still pass
> - ❌ All model references (ref()) must remain valid
>
> **Allowed:**
> - ✅ Rewrite SQL syntax (CTEs, joins, aggregations)
> - ✅ Change materialisation (table/view/ephemeral)
> - ✅ Optimise Snowflake dialect
> - ✅ Simplify inefficient patterns
>
> **Deliverable:**
> - Modified `models/` directory
> - New `output/optimised_report.csv` from your changes
> - Document what was optimised in each file

---

## 📋 Phase 3: Validation

### Run Comparison

```bash
python scripts/compare_reports.py \
    output/baseline_report.csv \
    output/optimised_report.csv
```

### Success Criteria

- ✅ Row counts identical
- ✅ Column names identical
- ✅ All numeric values identical
- ✅ dbt tests pass (100%)
- ✅ No errors during execution

### Metrics to Capture

```json
{
  "validation": {
    "status": "PASS",
    "baseline_rows": 420,
    "optimised_rows": 420,
    "columns_match": true,
    "dbt_tests_passed": 18,
    "execution_time_baseline_seconds": 12.5,
    "execution_time_optimised_seconds": 8.2,
    "speedup": "1.52x faster"
  }
}
```

---

## 🎯 Success Criteria Summary

| Criterion | Target | Status |
|-----------|--------|--------|
| Input project builds locally | ✅ | TBD |
| Baseline report generated | ✅ | TBD |
| Baseline metrics captured | ✅ | TBD |
| All dbt tests pass (baseline) | 18/18 | TBD |
| Artemis optimises SQL | ✅ | TBD |
| Optimised report generated | ✅ | TBD |
| Reports are bit-identical | ✅ | TBD |
| dbt tests pass (optimised) | 18/18 | TBD |
| Performance improved | ✅ | TBD |

---

## 📅 Timeline

- **Phase 1 (Week 1):** Build input project, generate baseline
- **Phase 2 (Week 2):** Artemis optimises
- **Phase 3 (Week 2-3):** Validate and measure
- **Demo (Week 3):** Present results

---

## 📞 Contacts

- **Input Project Lead:** Claude + Team
- **Artemis Lead:** [Artemis Team]
- **Validation:** [QA/Engineering]
- **Demo:** [Product/Sales]

---

**Status:** Phase 1 – Building Input Project
**Last Updated:** 2026-01-24
