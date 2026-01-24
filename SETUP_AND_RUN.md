# Setup & Execution Guide

## Quick Start (5 minutes)

### Prerequisites

1. **dbt installed** with Snowflake adapter
   ```bash
   pip install dbt-snowflake dbt-utils
   ```

2. **Snowflake credentials** set as environment variables
   ```bash
   export SNOWFLAKE_ACCOUNT="your_account"
   export SNOWFLAKE_USER="your_user"
   export SNOWFLAKE_PASSWORD="your_password"
   ```

3. **Snowflake resources** pre-created
   - Database: `BAIN_ANALYTICS`
   - Warehouse: `ANALYTICS_WH`
   - Schemas: `RAW`, `DEV` (for development), `PROD` (for production)
   - Role: `ANALYST` with necessary permissions

4. **Python 3.7+** with pandas installed
   ```bash
   pip install pandas
   ```

---

## Run the Pipeline

### Step 1: Full Pipeline Execution

```bash
bash run.sh
```

This will:
1. ✅ Install dbt packages
2. ✅ Load seed data (sample portfolios, trades, etc.)
3. ✅ Build all models (Pipeline A, B, C)
4. ✅ Run dbt tests
5. ✅ Generate documentation
6. ✅ Export baseline report to `output/baseline_report.csv`
7. ✅ Capture metrics to `output/baseline_metrics.json`

**Expected output:**
```
✅ Pipeline Complete!

📁 Outputs:
   ✓ output/baseline_report.csv
   ✓ output/baseline_metrics.json
```

---

## Output Structure

After successful run, you'll have:

```
sample-dbt-project/
├── output/
│   ├── baseline_report.csv          ← Main report (final output)
│   └── baseline_metrics.json        ← Baseline performance metrics
├── target/
│   ├── manifest.json                ← dbt DAG and model metadata
│   ├── run_results.json             ← Execution results
│   └── compiled/                    ← Compiled SQL
└── logs/
    └── dbt.log                      ← dbt execution logs
```

---

## Inspect the Data

### View the Report

```bash
# Show first 10 rows
head -20 output/baseline_report.csv

# Count rows
wc -l output/baseline_report.csv

# View full report
cat output/baseline_report.csv
```

### View Baseline Metrics

```bash
cat output/baseline_metrics.json
```

Example output:
```json
{
  "timestamp": "2026-01-24T10:30:00.123456",
  "dbt_version": "dbt 1.5.0",
  "database": "snowflake",
  "summary": {
    "total_models": 33,
    "total_tests": 18,
    "tests_passed": 18,
    "tests_failed": 0
  },
  "models": {
    "stg_cashflows": { ... },
    "fact_cashflow_summary": { ... },
    ...
  }
}
```

---

## Understand the Pipeline

### Three Pipelines

#### Pipeline A: Simple Cashflow Analytics
```
Raw Data (RAW.cashflows, RAW.portfolios)
    ↓
Staging (stg_cashflows, stg_portfolios)
    ↓
Mart (fact_cashflow_summary)
    ↓
Report (report_monthly_cashflows) ← Final output for demo
```

**Models:**
- `stg_cashflows` – Clean cashflow transactions
- `stg_portfolios` – Portfolio master data
- `fact_cashflow_summary` – Monthly cashflow aggregation
- `report_monthly_cashflows` – LP reporting view (final)

---

#### Pipeline B: Medium Complexity Trade Analytics
```
Raw Data (trades, securities, market_prices, brokers)
    ↓
Staging (stg_trades, stg_securities, etc.)
    ↓
Intermediate (int_trades_enriched, int_trade_pnl)
    ↓
Marts (fact_portfolio_positions, fact_trade_summary)
    ↓
Report (report_trading_performance)
```

---

#### Pipeline C: Complex Portfolio Performance
```
Raw Data (positions_daily, benchmarks, valuations, etc.)
    ↓
Staging (multiple stg_* models)
    ↓
Intermediate (7 complex transformation models)
    ↓
Facts (4 fact tables)
    ↓
Reports (2 reporting views)
```

---

## Validation & Comparison

### After Artemis Optimizes

Once Artemis returns the optimized project:

1. **Copy optimized models to your local project**
   ```bash
   cp -r artemis_optimized/models/* models/
   ```

2. **Run the pipeline again**
   ```bash
   bash run.sh
   ```

3. **This generates a new report** (or manually create `output/optimised_report.csv`)

4. **Compare the reports**
   ```bash
   python scripts/compare_reports.py \
     output/baseline_report.csv \
     output/optimised_report.csv \
     output/comparison_result.json
   ```

### Expected Comparison Output

```
======================================================================
📊 REPORT COMPARISON - Artemis Demo Validation
======================================================================

✅ Shape: (420, 15) (identical)

✅ Columns: 15 columns (identical)

✅ Values: All values identical (bit-for-bit)

✅ Financial Metrics:
   - Total Sum: $31,500,000.00 (identical)
   - Total Mean: $2,100,000.00 (identical)

======================================================================
✅ SUCCESS: Reports are identical!
Artemis optimization is validated - outputs unchanged.
======================================================================
```

---

## Troubleshooting

### Issue: "Snowflake credentials not set"

**Solution:** Set environment variables before running

```bash
export SNOWFLAKE_ACCOUNT="xy12345.us-east-1"
export SNOWFLAKE_USER="your_user@company.com"
export SNOWFLAKE_PASSWORD="your_password"
bash run.sh
```

Or create a `.env` file and source it:

```bash
cat > .env << EOF
export SNOWFLAKE_ACCOUNT="xy12345.us-east-1"
export SNOWFLAKE_USER="your_user@company.com"
export SNOWFLAKE_PASSWORD="your_password"
EOF

source .env
bash run.sh
```

---

### Issue: "dbt packages not found"

**Solution:** Install dbt packages

```bash
dbt deps
```

---

### Issue: "Permission denied" on Snowflake

**Solution:** Check your Snowflake role permissions

The `ANALYST` role needs:
- `USAGE` on `BAIN_ANALYTICS` database
- `USAGE` on `RAW`, `DEV`, `PROD` schemas
- `CREATE TABLE`, `CREATE VIEW` on schemas
- `USAGE` on `ANALYTICS_WH` warehouse

Ask your Snowflake admin to grant these permissions:

```sql
GRANT USAGE ON DATABASE BAIN_ANALYTICS TO ROLE ANALYST;
GRANT USAGE ON SCHEMA BAIN_ANALYTICS.RAW TO ROLE ANALYST;
GRANT USAGE ON SCHEMA BAIN_ANALYTICS.DEV TO ROLE ANALYST;
GRANT CREATE TABLE, CREATE VIEW ON SCHEMA BAIN_ANALYTICS.DEV TO ROLE ANALYST;
GRANT USAGE ON WAREHOUSE ANALYTICS_WH TO ROLE ANALYST;
```

---

### Issue: "Model not found" or other SQL errors

**Solution:** Check model dependencies

```bash
# View the DAG
dbt docs generate
open target/index.html  # On Mac
start target/index.html # On Windows
```

Or check logs:

```bash
tail -100 logs/dbt.log
```

---

## Manual Execution (Step-by-Step)

If you prefer to run commands manually:

```bash
# 1. Install packages
dbt deps

# 2. Load seed data
dbt seed --full-refresh

# 3. Build models
dbt run

# 4. Run tests
dbt test

# 5. Generate docs
dbt docs generate

# 6. Query the final report (example for Pipeline A)
# Use your SQL client or snowsql:
#   SELECT * FROM BAIN_ANALYTICS.DEV.report_monthly_cashflows;

# 7. Export to CSV (example using snowsql)
snowsql -a $SNOWFLAKE_ACCOUNT -u $SNOWFLAKE_USER \
  -d BAIN_ANALYTICS -s DEV \
  -q "SELECT * FROM pipeline_a.report_monthly_cashflows;" \
  -o output_format=csv > output/baseline_report.csv

# 8. Capture metrics
python scripts/capture_metrics.py > output/baseline_metrics.json
```

---

## Sample Data

The project includes realistic sample data for:

| Seed File | Rows | Description |
|-----------|------|-------------|
| `sample_portfolios.csv` | 4 | Portfolio master data |
| `sample_cashflows.csv` | 50 | Cashflow transactions |
| `sample_trades.csv` | 50 | Trade records |
| `sample_positions_daily.csv` | 50 | Daily position snapshots |
| `sample_market_prices.csv` | 90 | Security prices |
| `sample_brokers.csv` | 5 | Broker reference data |
| `sample_benchmarks.csv` | 3 | Benchmark indices |
| `sample_benchmark_returns.csv` | 57 | Benchmark returns |
| `sample_portfolio_benchmarks.csv` | 8 | Portfolio-Benchmark mappings |
| `sample_valuations.csv` | 44 | Portfolio valuations |

All data spans 2020-2024 for realistic testing.

---

## Next: Hand Off to Artemis

Once you have the baseline report:

1. **Commit the baseline**
   ```bash
   git add output/baseline_report.csv
   git add output/baseline_metrics.json
   git commit -m "baseline: initial report before optimization"
   ```

2. **Package for Artemis**
   - Entire `sample-dbt-project/` folder
   - Include all models, seeds, tests, dbt_project.yml
   - Include `run.sh` and scripts
   - Include baseline metrics and report

3. **Brief Artemis**
   ```
   Optimize these dbt models for Snowflake.
   Keep report outputs IDENTICAL.
   Constraints:
     - No column name changes
     - No numeric value changes
     - All tests must pass
   Allowed:
     - SQL refactoring
     - Materialization changes
     - Performance optimizations
   ```

4. **Artemis Returns**
   - Optimized `models/` directory
   - Updated `output/optimised_report.csv`
   - Summary of changes

5. **Validate**
   ```bash
   python scripts/compare_reports.py \
     output/baseline_report.csv \
     output/optimised_report.csv
   ```

---

## Getting Help

- **dbt docs:** https://docs.getdbt.com
- **dbt Slack:** https://community.getdbt.com
- **Snowflake docs:** https://docs.snowflake.com
- **This project:** Check `DEMO_WORKFLOW_BULLETS.md` and `DEMO_WORKFLOW_TEAM.md`

---

**Status:** Ready for execution
**Last Updated:** 2026-01-24
