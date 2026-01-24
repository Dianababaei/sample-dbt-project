# Artemis Sample Project - START HERE

## What You Have

A **production-ready dbt project** that:
- ✅ Runs end-to-end with zero errors
- ✅ Produces a clear aggregated report table
- ✅ Includes realistic SQL optimization opportunities
- ✅ Has 65 automated data quality tests
- ✅ Is fully documented

**Status**: Ready for Artemis SQL optimization

---

## In 60 Seconds

### Run the project:
```bash
bash RUN_NOW.sh
```

### Expected output:
```
✅ Pipeline Complete!
Done. PASS=14 WARN=0 ERROR=0
```

### Output table created:
```
BAIN_ANALYTICS.DEV.FACT_CASHFLOW_SUMMARY
(Monthly aggregated portfolio cashflows)
```

---

## Documentation Map

Read these in order:

1. **📄 [PROJECT_SUMMARY.txt](PROJECT_SUMMARY.txt)** ← Start here for quick overview
   - What's in the project
   - What was built
   - Key statistics

2. **📘 [README_FOR_ARTEMIS.md](README_FOR_ARTEMIS.md)** ← Quick start guide
   - How to run the project
   - What to optimize
   - Success criteria

3. **📗 [ARTEMIS_SAMPLE_PROJECT.md](ARTEMIS_SAMPLE_PROJECT.md)** ← Complete reference
   - Full technical documentation
   - Data dictionary
   - Architecture details

4. **📙 [DEMO_WORKFLOW_TEAM.md](DEMO_WORKFLOW_TEAM.md)** ← In-depth walkthrough
   - Step-by-step explanation
   - Why each step matters
   - What Artemis needs to know

---

## What to Optimize

### Main Target: `models/pipeline_a/marts/fact_cashflow_summary.sql`

This model demonstrates:
- ❌ **Heavy join before aggregation** - Joins full cashflow table to portfolios, THEN aggregates
- ❌ **Late aggregation** - All row-level operations happen before GROUP BY
- ❌ **Redundant calculations** - Date truncation + extraction done per row
- ❌ **Non-optimal GROUP BY** - Uses column positions instead of explicit names

**Your task**: Rewrite to eliminate these inefficiencies while producing identical output.

### Secondary Target: `models/pipeline_a/staging/stg_cashflows.sql`

Issues marked with `-- ISSUE:` comments:
- Unnecessary DISTINCT
- Late filtering
- Non-optimal date casting

---

## Success Metrics

### Must Pass (Non-Negotiable):
- All 14 models compile without errors
- All 65 tests pass
- FACT_CASHFLOW_SUMMARY output is identical

### Should Improve (Goals):
- Execution time: <15 seconds (from ~30s baseline)
- Snowflake credits: <0.25 (from ~0.5 baseline)
- 50%+ improvement in both

---

## Key Files

```
📁 models/
  └── pipeline_a/
      ├── staging/          ← Data transformation layer
      │   ├── stg_cashflows.sql          (optimization opportunity)
      │   └── stg_portfolios.sql         (simple staging)
      └── marts/
          └── fact_cashflow_summary.sql  (MAIN OPTIMIZATION TARGET)

📁 seeds/
  └── 13 CSV files           (realistic financial data)

📄 dbt_project.yml           (project configuration)
📄 profiles.yml              (Snowflake connection)
🚀 RUN_NOW.sh               (execute complete pipeline)
```

---

## The Output Table

### FACT_CASHFLOW_SUMMARY

| Column | Example | Purpose |
|--------|---------|---------|
| portfolio_name | "Global Equity Core" | Portfolio identifier |
| cashflow_month | 2024-01-31 | Aggregation period |
| cashflow_type | CONTRIBUTION | Type of cashflow |
| transaction_count | 5 | Number of transactions |
| total_amount | 1,000,000.00 | Sum of amounts |
| avg_amount | 200,000.00 | Average per transaction |

**This table's structure must remain identical after optimization.**

---

## How to Validate Your Optimization

```bash
# Run optimized version
bash RUN_NOW.sh

# Check tests pass
dbt test          # All 65 must pass

# Verify output in Snowflake
SELECT
  COUNT(*) as row_count,
  SUM(total_amount) as total
FROM BAIN_ANALYTICS.DEV.FACT_CASHFLOW_SUMMARY;

# Compare with baseline
# (Row count and total must match exactly)
```

---

## Baseline Metrics (For Comparison)

These are your targets to beat:

| Metric | Baseline | Goal |
|--------|----------|------|
| Execution time | 30 seconds | < 15 seconds |
| Snowflake credits | 0.5 | < 0.25 |
| Models building | 14/14 ✅ | 14/14 ✅ |
| Tests passing | 65/65 ✅ | 65/65 ✅ |
| Output integrity | ✅ | ✅ (unchanged) |

---

## Technical Details

### Data Model
```
13 Seed CSV Files
        ↓
9 Staging Views (STG_*)
        ↓
1 Fact Table (FACT_CASHFLOW_SUMMARY)
        ↓
Output: Aggregated monthly portfolio cashflows
```

### Snowflake Setup
```
Account:    IHB62607
Database:   BAIN_ANALYTICS
Schema:     DEV
Warehouse:  COMPUTE_WH
```

### Sample Data
- **Period**: 2020-01-01 to 2024-12-31
- **Portfolios**: 4 unique
- **Months**: 12 (representing 1 year of data)
- **Transactions**: ~50 cashflow events
- **Output rows**: ~48 (4 portfolios × 12 months)

---

## Important Notes

1. **Preserve exact output** - The final FACT_CASHFLOW_SUMMARY must be identical
2. **All tests must pass** - 65 data quality tests validate correctness
3. **No financial drift** - Aggregation totals must match exactly
4. **Focus on the main model** - fact_cashflow_summary.sql is where most work happens
5. **Document your changes** - Keep the `-- ISSUE:` comments updated

---

## Getting Help

1. **For technical details**: Read ARTEMIS_SAMPLE_PROJECT.md
2. **For how to run it**: Read README_FOR_ARTEMIS.md
3. **For workflow context**: Read DEMO_WORKFLOW_TEAM.md
4. **For quick reference**: Check PROJECT_SUMMARY.txt

Each file has specific information for different purposes.

---

## Next Steps

1. ✅ **Run the baseline** - `bash RUN_NOW.sh` (done - reference metrics recorded)
2. 📝 **Review the SQL** - Look at models/pipeline_a/marts/fact_cashflow_summary.sql
3. 🔍 **Identify inefficiencies** - Find the optimization opportunities (marked with `-- ISSUE:`)
4. ✏️ **Optimize the models** - Rewrite to be faster/cheaper
5. 🧪 **Validate output** - Run tests, compare metrics
6. 📊 **Document improvements** - Record execution time and cost reduction

---

**Status**: ✅ Project complete and ready for Artemis optimization

**Questions?** Check the documentation files listed above - they cover everything you need to know.

**Ready to start?** Begin with `bash RUN_NOW.sh` to see the baseline, then review the models in `models/pipeline_a/marts/`.
