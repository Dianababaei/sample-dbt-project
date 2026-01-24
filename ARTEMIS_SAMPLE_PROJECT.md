# Artemis Sample Project: Bain Capital Portfolio Analytics

## Project Overview

This is a **production-ready dbt sample project** designed as input for the Artemis SQL optimization engine. It demonstrates realistic data transformation patterns that Artemis can analyze and optimize.

### Business Context
- **Organization**: Bain Capital
- **Domain**: Portfolio Analytics & Financial Management
- **Purpose**: Build a data warehouse that aggregates multi-pipeline data (cashflows, trades, positions) into reporting tables

### Key Characteristics
- **33 dbt models** across 3 independent pipelines
- **13 CSV seed files** providing realistic sample data (2020-2024 time period)
- **9 staging models** (data layer with embedded optimization opportunities)
- **Final output**: `FACT_CASHFLOW_SUMMARY` - aggregated monthly portfolio cashflows
- **Execution time**: ~30 seconds end-to-end
- **Snowflake cost**: Minimal (suitable for testing and optimization demonstrations)

---

## Project Structure

```
sample-dbt-project/
├── models/
│   ├── pipeline_a/
│   │   ├── staging/          # Raw data layer (9 views)
│   │   │   ├── stg_cashflows.sql          ← Has optimization opportunities
│   │   │   └── stg_portfolios.sql
│   │   └── marts/
│   │       └── fact_cashflow_summary.sql  ← **FINAL REPORT TABLE**
│   ├── pipeline_b/           # Trade analytics (disabled for this baseline)
│   │   ├── staging/
│   │   └── intermediate/
│   └── pipeline_c/           # Portfolio analytics (disabled for this baseline)
│       ├── staging/
│       └── intermediate/
├── seeds/
│   ├── sample_cashflows.csv         # 50 rows, 2020-2024
│   ├── sample_portfolios.csv        # Portfolio master data
│   ├── sample_trades.csv            # Trade transactions
│   ├── sample_securities.csv        # Security master data
│   ├── sample_market_prices.csv     # Daily market prices
│   ├── sample_brokers.csv           # Broker reference
│   ├── sample_positions_daily.csv   # Daily positions
│   ├── sample_valuations.csv        # Portfolio NAV
│   ├── sample_benchmarks.csv        # Benchmark indices
│   ├── sample_benchmark_returns.csv # Benchmark returns
│   ├── sample_portfolio_benchmarks.csv
│   ├── sample_fund_hierarchy.csv
│   └── dim_date.csv                 # Date dimension
├── dbt_project.yml          # Project configuration
├── profiles.yml             # Snowflake connection config
└── RUN_NOW.sh              # Automated execution script
```

---

## Running the Project

### Prerequisites
- dbt 1.11+ with Snowflake adapter
- Snowflake account (already configured: `IHB62607`)
- Credentials in environment variables or profiles.yml

### Execution (Fastest Method)
```bash
bash RUN_NOW.sh
```

This runs:
1. `dbt deps` - Install dependencies
2. `dbt seed` - Load CSV data
3. `dbt run` - Execute models
4. `dbt test` - Run data quality tests
5. `dbt docs generate` - Create documentation

### Expected Output
```
✅ Pipeline Complete!
Done. PASS=14 WARN=0 ERROR=0 SKIP=0 TOTAL=14
```

### Snowflake Location
```
Database: BAIN_ANALYTICS
Schema:   DEV
Seed Tables (RAW):
  - SAMPLE_CASHFLOWS
  - SAMPLE_PORTFOLIOS
  - SAMPLE_TRADES
  - ... (13 total)

Output Table (FACT):
  - FACT_CASHFLOW_SUMMARY  ← Query this to validate optimization
```

---

## Final Output: FACT_CASHFLOW_SUMMARY

### Purpose
Monthly aggregation of all portfolio cashflows with comprehensive dimensions.

### Structure

| Column | Type | Description |
|--------|------|-------------|
| `cashflow_summary_key` | STRING | Surrogate key (MD5 hash) |
| `portfolio_id` | STRING | Portfolio identifier (PF001, PF002, ...) |
| `portfolio_name` | STRING | Portfolio display name |
| `portfolio_type` | STRING | Type (EQUITY, FIXED_INCOME, etc.) |
| `fund_id` | STRING | Parent fund identifier |
| `cashflow_month` | DATE | Month of cashflow |
| `cashflow_quarter` | DATE | Quarter of cashflow |
| `cashflow_year` | DATE | Year of cashflow |
| `year_num` | INT | Year component |
| `month_num` | INT | Month component (1-12) |
| `quarter_num` | INT | Quarter component (1-4) |
| `cashflow_type` | STRING | Type (CONTRIBUTION, DISTRIBUTION, etc.) |
| `currency` | STRING | Currency code (USD) |
| `transaction_count` | INT | Count of transactions |
| `total_amount` | DECIMAL | Sum of amounts |
| `avg_amount` | DECIMAL | Average amount |
| `min_amount` | DECIMAL | Minimum amount |
| `max_amount` | DECIMAL | Maximum amount |

### Sample Query
```sql
SELECT
  portfolio_name,
  cashflow_month,
  cashflow_type,
  transaction_count,
  total_amount,
  avg_amount
FROM BAIN_ANALYTICS.DEV.FACT_CASHFLOW_SUMMARY
WHERE cashflow_year = DATE('2024-01-01')
ORDER BY portfolio_name, cashflow_month;
```

---

## Optimization Opportunities (For Artemis)

The models include embedded optimization points marked with `-- ISSUE:` comments:

### stg_cashflows.sql
1. **Unnecessary DISTINCT** - Source already has unique constraint
2. **Late filtering** - Date filter applied after expensive transformations
3. **Non-optimal date casting** - Could be optimized at source load

### fact_cashflow_summary.sql
1. **Heavy join before aggregation** - Joins full cashflow table to portfolios before GROUP BY
2. **Late aggregation** - All row-level calculations happen before grouping
3. **Redundant date calculations** - date_trunc + extract operations done per row
4. **Non-optimal GROUP BY** - Uses column positions instead of explicit names

### Pipeline B & C (Currently Disabled)
Additional models demonstrate:
- Multiple window functions recalculated unnecessarily
- Self-joins that could use LAG/LEAD
- Re-aggregation of already-aggregated data
- Complex cross-joins that could be simplified

---

## Key Metrics for Artemis

These metrics will be captured at baseline and compared after optimization:

### Execution Metrics
- **Total runtime**: Time to execute `dbt run`
- **Model-level runtimes**: Individual model execution times
- **Snowflake credits consumed**: Cost of all queries

### Data Validation Metrics
- **Row count** in FACT_CASHFLOW_SUMMARY (must remain identical after optimization)
- **Aggregation totals** (sum of amounts by portfolio/period - must not change)
- **Data quality test results** (must pass before and after)

### Query Performance
- Estimated scan volume (bytes)
- Number of table scans per model
- Join operations count

---

## Configuration

### Snowflake Connection (profiles.yml)
```yaml
bain_capital:
  dev:
    account: IHB62607
    user: diana
    password: [from environment]
    role: ACCOUNTADMIN
    database: BAIN_ANALYTICS
    warehouse: COMPUTE_WH
    schema: DEV
```

### dbt Configuration (dbt_project.yml)
```yaml
vars:
  start_date: '2020-01-01'
  end_date: '2024-12-31'
```

---

## Data Lineage

```
CSV Seeds (13 files)
     ↓
Staging Layer (9 views)
  - stg_cashflows (joins to source data)
  - stg_portfolios (basic SELECT)
  - stg_trades (enriched with categorization)
  - stg_securities (standardization logic)
  - ... (additional staging models)
     ↓
Fact Table (1 output table)
  - FACT_CASHFLOW_SUMMARY
    (aggregated by portfolio + period + cashflow type)
```

---

## Testing & Validation

The project includes **65 data quality tests** across:
- **Not null constraints**: Key columns must have values
- **Unique constraints**: Primary keys are unique
- **Referential integrity**: Foreign keys exist in dimension tables
- **Accepted values**: Enum fields contain expected values
- **Custom assertions**: Business logic validation

All tests pass in the baseline execution.

---

## Next Steps for Artemis

1. **Take this entire project** as input
2. **Analyze the DAG and model logic** for optimization opportunities
3. **Apply transformations** that:
   - Rewrite models to eliminate marked ISSUES
   - Consolidate window functions
   - Push filters upstream
   - Optimize joins
   - Reduce redundant calculations
4. **Produce optimized versions** of all models
5. **Verify output identity**:
   - `FACT_CASHFLOW_SUMMARY` has same row count
   - All aggregation totals match baseline exactly
   - All data quality tests pass

---

## Files for Artemis

Send to Artemis for optimization analysis:

```
Essential:
  - models/           (All model SQL files)
  - seeds/            (All CSV data files)
  - dbt_project.yml   (Project config)
  - profiles.yml      (Connection config - sanitized)

Reference:
  - RUN_NOW.sh        (Execution script)
  - This file         (Project documentation)
  - ARTEMIS_INPUT_READY.md (Quick reference)
```

---

## Success Criteria

✅ **Baseline Complete** when:
- All 14 models build successfully (0 errors)
- All 65 tests pass
- FACT_CASHFLOW_SUMMARY contains expected data
- Execution time and cost are documented

✅ **Optimization Valid** when:
- All 14 models build with optimized SQL
- All 65 tests still pass
- FACT_CASHFLOW_SUMMARY output is byte-for-byte identical
- Execution time is reduced
- Snowflake credits consumed is reduced

---

## Contact & Support

For questions about this sample project:
- Review DEMO_WORKFLOW_TEAM.md for detailed walkthrough
- Check dbt documentation at ./target/index.html
- Examine individual model files for ISSUE comments

---

**Project Status**: ✅ READY FOR ARTEMIS OPTIMIZATION
**Last Updated**: 2026-01-25
**Baseline Execution Time**: ~30 seconds
**Snowflake Cost**: Minimal (testing tier)
