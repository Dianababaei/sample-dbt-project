# Artemis Sample Project - Quick Start Guide

## What This Project Is

A **fully-functional dbt project** that transforms raw financial data into an aggregated report table. Built as a test case for Artemis SQL optimization.

## Quick Start

```bash
# Navigate to project
cd sample-dbt-project

# Run complete pipeline
bash RUN_NOW.sh
```

**Expected Result:**
```
✅ Pipeline Complete!
✅ Models built: 14/14 (0 errors)
✅ Tests passed: 65/65
✅ Output table created: BAIN_ANALYTICS.DEV.FACT_CASHFLOW_SUMMARY
```

## The Deliverable

### Input Data
- **13 seed files** with realistic financial data (2020-2024)
- Portfolio, cashflow, trade, security, and valuation data
- Located in: `seeds/`

### Processing Pipeline
```
Raw Data (CSV seeds)
    ↓
9 Staging Models (Data transformation layer)
    ↓
1 Fact Table (Final aggregated output)
    ↓
FACT_CASHFLOW_SUMMARY
(Monthly portfolio cashflows with dimensions)
```

### Output Table

**Location**: `BAIN_ANALYTICS.DEV.FACT_CASHFLOW_SUMMARY`

**Key Metrics**:
- `transaction_count` - # of cashflow transactions
- `total_amount` - Sum of all amounts
- `avg_amount`, `min_amount`, `max_amount` - Statistical metrics

**Dimensions**:
- Portfolio (name, type, fund)
- Period (month, quarter, year)
- Cashflow type (contribution, distribution, etc.)

## Optimization Task

Your mission: **Rewrite the models to be faster/cheaper while producing identical output.**

### Models to Optimize

**Primary**: `models/pipeline_a/marts/fact_cashflow_summary.sql`
- Marked with `-- ISSUE:` comments highlighting optimization opportunities
- Heavy join before aggregation
- Redundant date calculations
- Non-optimal grouping

**Secondary**: `models/pipeline_a/staging/stg_cashflows.sql`
- Unnecessary DISTINCT
- Late filtering
- Could be simplified

### Success Criteria

✅ **All models execute without errors**
- No SQL compilation errors
- No data quality test failures

✅ **Output remains identical**
- Same number of rows in FACT_CASHFLOW_SUMMARY
- Same aggregation totals (no financial drift)
- All column values match exactly

✅ **Performance improves**
- Lower execution time
- Fewer Snowflake credits consumed
- Fewer table scans/bytes processed

## Key Files

| File | Purpose |
|------|---------|
| `RUN_NOW.sh` | Execute complete pipeline |
| `models/pipeline_a/mmarts/fact_cashflow_summary.sql` | **MAIN OUTPUT - Optimize this** |
| `models/pipeline_a/staging/stg_cashflows.sql` | Staging model with optimization points |
| `dbt_project.yml` | dbt configuration |
| `profiles.yml` | Snowflake connection |
| `ARTEMIS_SAMPLE_PROJECT.md` | Full documentation |

## Snowflake Setup

Connection details (already configured):
- **Account**: IHB62607
- **Database**: BAIN_ANALYTICS
- **Schema**: DEV
- **User**: diana

Seed data loads to: `BAIN_ANALYTICS.DEV.SAMPLE_*` tables
Models create in: `BAIN_ANALYTICS.DEV.STG_*` and `BAIN_ANALYTICS.DEV.FACT_*`

## Project Statistics

- **Lines of SQL**: ~2,000
- **Number of models**: 14 (9 staging, 1 fact output, 4 intermediate)
- **Data quality tests**: 65
- **CSV seed files**: 13
- **Total rows of sample data**: ~500
- **Time range**: 2020-2024
- **Execution time**: ~30 seconds

## Testing & Validation

All models include built-in validation:
```sql
-- 65 automated data quality tests:
- Not null checks on key columns
- Unique constraints on IDs
- Referential integrity verification
- Enum validation (accepted values only)
- Custom business logic assertions
```

Run tests after optimization:
```bash
dbt test
```

## Optimization Tips

1. **Focus on fact_cashflow_summary.sql first** - This is where most CPU is spent
2. **Look for the `-- ISSUE:` comments** - These point out specific problems
3. **The staging models feed the fact table** - Optimizing upstream has downstream impact
4. **Preserve exact output** - The aggregation logic must be logically equivalent
5. **Check test results** - 65 tests must pass before and after optimization

## Verification After Optimization

```bash
# Run optimized version
bash RUN_NOW.sh

# Check output matches baseline
dbt test  # All 65 tests must pass

# Validate fact table in Snowflake
SELECT
  COUNT(*) as row_count,
  SUM(total_amount) as total_amount
FROM BAIN_ANALYTICS.DEV.FACT_CASHFLOW_SUMMARY;
```

Document the metrics:
- Baseline execution time: [record before optimization]
- Optimized execution time: [record after optimization]
- Baseline credits: [record before]
- Optimized credits: [record after]
- Improvement: X% faster, Y% cheaper

## Documentation

- **ARTEMIS_SAMPLE_PROJECT.md** - Complete technical documentation
- **DEMO_WORKFLOW_TEAM.md** - End-to-end workflow guide
- **target/index.html** - Interactive dbt documentation (after running)

## Questions?

Review the ISSUE comments in the SQL files to understand:
- Why this approach is suboptimal
- What the better approach would be
- How to validate the optimization maintains correctness

---

**Status**: ✅ Ready for optimization
**Last Run**: Successfully completed
**Next Step**: Optimize models while preserving output
