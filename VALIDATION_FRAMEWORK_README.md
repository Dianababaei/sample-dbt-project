# Validation Framework - Complete Guide

This document provides the complete validation framework for Task 3/5: **Validate Optimizations Against Baseline KPIs**.

---

## Quick Start (30 seconds)

```bash
# 1. Set credentials
export SNOWFLAKE_ACCOUNT="your_account"
export SNOWFLAKE_USER="your_user"
export SNOWFLAKE_PASSWORD="your_password"

# 2. Run validation
bash run_pipeline.sh

# 3. View results
python benchmark/compare_kpis.py
```

**Expected**: All three criteria pass ✅

---

## Table of Contents

1. [Framework Overview](#framework-overview)
2. [Success Criteria](#success-criteria)
3. [Detailed Validation Steps](#detailed-validation-steps)
4. [KPI System Explained](#kpi-system-explained)
5. [Troubleshooting](#troubleshooting)
6. [Reference Documents](#reference-documents)

---

## Framework Overview

### What Is Being Validated?

Three SQL optimizations implemented in Task #2:

| Model | Optimization | Expected Impact |
|-------|--------------|-----------------|
| `stg_cashflows.sql` | Early date filtering | 10-20% volume reduction |
| `stg_portfolios.sql` | Status filter at source | Consistent filtering |
| `fact_cashflow_summary.sql` | Pre-aggregation before joins | 30-50% row reduction |

### How Does Validation Work?

```
Run Optimized Pipeline
        ↓
Extract 5 KPIs from Query Execution
        ├─ KPI 1: Runtime (seconds)
        ├─ KPI 2: Work metrics (rows, bytes)
        ├─ KPI 3: Output validation (hash, count)
        ├─ KPI 4: Query complexity
        └─ KPI 5: Cost estimation
        ↓
Compare Against Baseline Metrics
        ↓
Generate Validation Report
        ↓
PASS/FAIL Decision
```

### Baseline Metrics (Golden Truth)

From `benchmark/baseline/report.json`:

| KPI | Metric | Value |
|-----|--------|-------|
| KPI 1 | Runtime | 4.5319 seconds |
| KPI 2 | Rows | 426 rows |
| KPI 2 | Bytes Scanned | 436,224 bytes |
| KPI 3 | Output Hash | `4ae5e137a8fb74272f61f38fac934d793da5b1e81fd79be573c55b29f7bdf08e` |
| KPI 3 | Row Count | 426 rows |
| KPI 4 | Complexity | 5.0/10 (1 join, 1 CTE, 1 window function) |
| KPI 5 | Credits | 0.302125 credits |

---

## Success Criteria

### 3 Mandatory Requirements (ALL MUST PASS)

#### Requirement 1: Output Hash Must Match
```
Baseline: 4ae5e137a8fb74272f61f38fac934d793da5b1e81fd79be573c55b29f7bdf08e
Target:   [SAME VALUE]
Rule:     MUST be identical (bit-for-bit equivalence)
Proof:    SHA256 hash of result set (426 rows)
```

**What This Means**: 
- No data has changed
- Business logic is correct
- Every row, every column, every value matches

**If This Fails**:
- ❌ Optimization altered business logic
- ❌ Data loss or corruption detected
- ❌ Aggregation logic broken
- **Action**: Roll back and investigate

---

#### Requirement 2: Row Count Must Match
```
Baseline: 426 rows
Target:   426 rows
Rule:     MUST be equal
Proof:    SELECT COUNT(*) FROM FACT_CASHFLOW_SUMMARY
```

**What This Means**:
- No rows lost
- No duplicate rows created
- Join and filter logic intact

**If This Fails**:
- ❌ Filtering too aggressive or too loose
- ❌ Join condition creates/loses records
- ❌ Data completeness compromised
- **Action**: Review WHERE clauses and JOIN conditions

---

#### Requirement 3: Runtime Must Improve
```
Baseline: 4.5319 seconds
Target:   < 4.5319 seconds
Rule:     MUST show improvement
Proof:    wall-clock execution time via time.time()
Expected: 15-25% faster (3.4-3.8 seconds)
```

**What This Means**:
- Optimization is effective
- Pre-aggregation reducing row volume
- Early filtering eliminating waste
- Query runs faster

**If This Fails**:
- ❌ Optimization not effective
- ❌ Bottleneck is elsewhere
- ❌ Pre-aggregation may not be reducing rows
- **Action**: Review query profile in Snowflake

---

### Additional Validation Points (Should Pass)

| Item | Criterion | Expected |
|------|-----------|----------|
| All Tests | Data quality | 65/65 PASS |
| Bytes Scanned | Efficiency | ≤ 436,224 bytes |
| Credits | Cost | < 0.302125 credits |
| Complexity | Simplicity | ≤ 5.0/10 |

---

## Detailed Validation Steps

### Step 1: Prepare Environment

```bash
# Set Snowflake credentials
export SNOWFLAKE_ACCOUNT="your_account_id"
export SNOWFLAKE_USER="your_username"
export SNOWFLAKE_PASSWORD="your_password"

# Verify credentials work
python3 -c "
from snowflake.connector import connect
conn = connect(
    account=os.getenv('SNOWFLAKE_ACCOUNT'),
    user=os.getenv('SNOWFLAKE_USER'),
    password=os.getenv('SNOWFLAKE_PASSWORD')
)
print('✓ Connected to Snowflake')
"
```

---

### Step 2: Execute Pipeline

```bash
# Make scripts executable
chmod +x run_pipeline.sh extract_report.py

# Run the full pipeline
bash run_pipeline.sh
```

**This will**:
1. ✅ Install dbt dependencies
2. ✅ Load 13 CSV seed files
3. ✅ Build 3 optimized models
4. ✅ Run 65 data quality tests
5. ✅ Execute benchmark query
6. ✅ Generate candidate report
7. ✅ Compare against baseline
8. ✅ Output results

**Expected Duration**: 3-5 minutes

---

### Step 3: Check Exit Code

```bash
echo $?
```

**Expected**: `0` (success)
**If Failure**: Exit code `1` indicates failure (see troubleshooting)

---

### Step 4: Verify Candidate Report

```bash
# Check file exists and is recent
ls -lh benchmark/candidate/report.json

# View summary
python3 << 'EOF'
import json
with open('benchmark/candidate/report.json') as f:
    report = json.load(f)
    meta = report['metadata']
    
print(f"Runtime:    {meta['kpi_1_execution']['runtime_seconds']}s")
print(f"Rows:       {meta['kpi_3_output_validation']['row_count']}")
print(f"Hash:       {meta['kpi_3_output_validation']['output_hash'][:16]}...")
print(f"Credits:    {meta['kpi_5_cost_estimation']['credits_estimated']}")
EOF
```

---

### Step 5: Validate Critical Criteria

#### Check Hash Match
```bash
python3 << 'EOF'
import json

with open('benchmark/baseline/report.json') as f:
    baseline = json.load(f)
with open('benchmark/candidate/report.json') as f:
    candidate = json.load(f)

b_hash = baseline['metadata']['kpi_3_output_validation']['output_hash']
c_hash = candidate['metadata']['kpi_3_output_validation']['output_hash']

match = b_hash == c_hash
print(f"Hash Match: {'✅ PASS' if match else '❌ FAIL'}")
if not match:
    print(f"  Baseline:  {b_hash}")
    print(f"  Candidate: {c_hash}")
EOF
```

#### Check Row Count Match
```bash
python3 << 'EOF'
import json

with open('benchmark/baseline/report.json') as f:
    baseline = json.load(f)
with open('benchmark/candidate/report.json') as f:
    candidate = json.load(f)

b_rows = baseline['metadata']['kpi_3_output_validation']['row_count']
c_rows = candidate['metadata']['kpi_3_output_validation']['row_count']

match = b_rows == c_rows
print(f"Row Count: {'✅ PASS' if match else '❌ FAIL'}")
if not match:
    print(f"  Baseline:  {b_rows} rows")
    print(f"  Candidate: {c_rows} rows")
EOF
```

#### Check Runtime Improvement
```bash
python3 << 'EOF'
import json

with open('benchmark/baseline/report.json') as f:
    baseline = json.load(f)
with open('benchmark/candidate/report.json') as f:
    candidate = json.load(f)

b_time = baseline['metadata']['kpi_1_execution']['runtime_seconds']
c_time = candidate['metadata']['kpi_1_execution']['runtime_seconds']
improvement = ((b_time - c_time) / b_time) * 100

passes = c_time < b_time
print(f"Runtime: {'✅ PASS' if passes else '❌ FAIL'}")
print(f"  Baseline:  {b_time:.4f}s")
print(f"  Optimized: {c_time:.4f}s")
print(f"  Improvement: {improvement:+.1f}%")
EOF
```

---

### Step 6: Detailed Comparison

```bash
python benchmark/compare_kpis.py
```

**Expected Output**:
```
======================================================================
Artemis Optimization Report - KPI Comparison
======================================================================

KPI 1: EXECUTION TIME (Runtime)
----------------------------------------------------------------------
  Baseline:  4.5319s
  Optimized: X.XXXXs
  Change:    DOWN X.X%

KPI 2: WORK METRICS (Output Size)
----------------------------------------------------------------------
  Baseline:  426 rows
  Optimized: 426 rows

KPI 3: OUTPUT VALIDATION (Equivalence Check)
----------------------------------------------------------------------
  Status: [OK] IDENTICAL (output equivalence guaranteed)

KPI 4: QUERY COMPLEXITY (Structure Analysis)
----------------------------------------------------------------------
  Baseline complexity:  5.0/10
  Optimized complexity: X.X/10

KPI 5: COST ESTIMATION (Bytes Scanned -> Credits)
----------------------------------------------------------------------
  Baseline:  0.302125 credits
  Optimized: X.XXXXXX credits
  Change:    DOWN X.X% fewer credits
```

---

## KPI System Explained

### KPI 1: Execution Time
- **What**: Wall-clock runtime in seconds
- **How Measured**: `time.time()` before and after query
- **Baseline**: 4.5319 seconds
- **Target**: < 4.5319 seconds (improvement required)
- **Why**: Proves optimization actually speeds up query execution

### KPI 2: Work Metrics
- **What**: Rows and bytes processed
- **How Measured**: `QUERY_PROFILE` from Snowflake
- **Baseline**: 426 rows, 436,224 bytes
- **Target**: Same rows, fewer bytes (efficiency)
- **Why**: Shows if optimization reduces data movement

### KPI 3: Output Validation
- **What**: SHA256 hash + row count of result
- **How Measured**: Hash of JSON-serialized output
- **Baseline**: Hash `4ae5e137...`, Count 426
- **Target**: Identical hash, identical count
- **Why**: Proves bit-for-bit correctness, no data drift

### KPI 4: Query Complexity
- **What**: Number of joins, CTEs, window functions, etc.
- **How Measured**: Regex parsing of SQL text
- **Baseline**: 5.0/10 (1 join, 1 CTE, 1 window function)
- **Target**: ≤ 5.0/10 (maintain or simplify)
- **Why**: Simpler queries are more maintainable

### KPI 5: Cost Estimation
- **What**: Estimated Snowflake credits
- **How Measured**: Runtime × warehouse credits/sec
- **Baseline**: 0.302125 credits (at 4 credits/sec for Medium warehouse)
- **Target**: < 0.302125 credits (cost reduction)
- **Why**: Connects runtime improvement to cost savings

---

## Troubleshooting

### Issue: "Snowflake credentials not set"

**Cause**: Environment variables not exported

**Solution**:
```bash
export SNOWFLAKE_ACCOUNT="xy12345"
export SNOWFLAKE_USER="username"
export SNOWFLAKE_PASSWORD="password"
```

**Verify**:
```bash
echo $SNOWFLAKE_ACCOUNT
```

---

### Issue: "Cannot connect to Snowflake"

**Causes**: 
1. Credentials wrong
2. Account doesn't exist
3. User doesn't have permissions
4. Network blocked

**Solutions**:
```bash
# Test credentials
python3 -c "
from snowflake.connector import connect
conn = connect(
    account='$SNOWFLAKE_ACCOUNT',
    user='$SNOWFLAKE_USER',
    password='$SNOWFLAKE_PASSWORD'
)
print('Connected!')
"

# Check account format (should be: xy12345, not xy12345.us-east-1)
# Check user exists and password is current
# Check firewall/VPN if on corporate network
```

---

### Issue: "dbt deps fails"

**Solution**:
```bash
# Clear cache and retry
rm -rf dbt_packages/
dbt deps --upgrade
```

---

### Issue: "Hash mismatch"

**Cause**: Business logic changed incorrectly

**Debug Steps**:
```bash
# 1. Check row counts match
SELECT COUNT(*) FROM FACT_CASHFLOW_SUMMARY;
# Should be 426

# 2. Check for NULL values
SELECT COUNT(*) FROM FACT_CASHFLOW_SUMMARY WHERE CASHFLOW_SUMMARY_KEY IS NULL;
# Should be 0

# 3. Spot check data
SELECT * FROM FACT_CASHFLOW_SUMMARY LIMIT 1;
# Compare values with baseline
```

**Fix**:
- Review aggregation logic in fact_cashflow_summary.sql
- Check GROUP BY columns
- Verify join conditions
- Roll back if necessary

---

### Issue: "Row count mismatch"

**Cause**: Filtering or join logic broken

**Debug Steps**:
```bash
# 1. Check staging models
SELECT COUNT(*) FROM STG_CASHFLOWS;
SELECT COUNT(*) FROM STG_PORTFOLIOS;

# 2. Check intermediate
SELECT COUNT(*) FROM aggregated_cashflows;
SELECT COUNT(*) FROM date_components;

# 3. Check joins
SELECT COUNT(*) FROM aggregated_cashflows ac
INNER JOIN portfolios p ON ac.portfolio_id = p.portfolio_id
INNER JOIN date_components dc ON ac.cashflow_date = dc.cashflow_date;
```

**Fix**:
- Review WHERE clauses
- Check JOIN conditions
- Verify INNER vs LEFT JOIN usage
- Test each CTE independently

---

### Issue: "No runtime improvement"

**Cause**: Optimization not effective

**Debug Steps**:
```bash
# 1. Check query profile
SELECT * FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())) LIMIT 1;

# 2. Check execution plan
EXPLAIN SELECT ... FROM FACT_CASHFLOW_SUMMARY;

# 3. Verify pre-aggregation is working
SELECT COUNT(*) FROM aggregated_cashflows;
# Should be much less than raw cashflows
```

**Fix**:
- Review pre-aggregation: is it actually reducing rows?
- Check if indexes are being used
- Consider different grouping columns
- Try alternative optimization pattern

---

## Reference Documents

### Overview Documents
- **TASK_3_SUMMARY.md** - High-level overview of task and expected outcomes
- **VALIDATION_RESULTS.md** - Comprehensive framework assessment
- **VALIDATION_CHECKLIST.md** - Step-by-step execution guide

### Template Documents
- **VALIDATION_STATUS_TEMPLATE.md** - Template for documenting results

### Operational Files
- **run_pipeline.sh** - Main orchestration script
- **extract_report.py** - KPI extraction and report generation
- **benchmark/compare.py** - Quick 3-rule validation
- **benchmark/compare_kpis.py** - Detailed 5-KPI comparison
- **benchmark/baseline/report.json** - Golden truth baseline metrics

### Source Code
- **models/pipeline_a/staging/stg_cashflows.sql** - Optimized (early filtering)
- **models/pipeline_a/staging/stg_portfolios.sql** - Optimized (status filter)
- **models/pipeline_a/marts/fact_cashflow_summary.sql** - Optimized (pre-aggregation)

---

## Document Reading Order

### For First-Time Users
1. **This file** (VALIDATION_FRAMEWORK_README.md) - Overview
2. **TASK_3_SUMMARY.md** - Understand objectives
3. **VALIDATION_CHECKLIST.md** - Execute step-by-step
4. **VALIDATION_STATUS_TEMPLATE.md** - Document results

### For Quick Reference
1. **VALIDATION_FRAMEWORK_README.md** → Quick Start section
2. **VALIDATION_CHECKLIST.md** → Copy Python commands
3. **VALIDATION_RESULTS.md** → Review expected outcomes

### For Troubleshooting
1. **VALIDATION_FRAMEWORK_README.md** → Troubleshooting section
2. **VALIDATION_CHECKLIST.md** → Failure Handling section
3. **VALIDATION_RESULTS.md** → Failure Handling Protocol

---

## Success Definition

✅ **Task 3 is COMPLETE when**:

1. ✅ Output hash matches exactly
2. ✅ Row count equals 426
3. ✅ Runtime < 4.5319 seconds
4. ✅ All 65 dbt tests pass
5. ✅ Results documented in VALIDATION_STATUS_TEMPLATE.md

**Outcome**: 
- If all above ✅ → **OPTIMIZATION ACCEPTED** → Proceed to Task #4
- If any ❌ → **DEBUG AND RETRY** → Fix issues and re-run

---

## Next Steps

### Immediate (Now)
1. Read TASK_3_SUMMARY.md
2. Review VALIDATION_CHECKLIST.md
3. Set Snowflake credentials

### Short Term (Next)
4. Execute: `bash run_pipeline.sh`
5. Work through VALIDATION_CHECKLIST.md
6. Document results in VALIDATION_STATUS_TEMPLATE.md

### Follow-Up (Task #4)
7. Run full test suite
8. Verify data quality
9. Document final results

---

## Support

### Getting Help

1. **Check troubleshooting section** in this document
2. **Review error messages** in logs/ directory
3. **Examine detailed comparison** output from compare_kpis.py
4. **Compare baseline vs candidate** JSON reports manually
5. **Check Snowflake query profile** for execution details

### Key Error Messages to Look For

```bash
# In run_pipeline.sh output
FAIL: Output hash mismatch
FAIL: Row count mismatch
FAIL: Slower than baseline

# In dbt logs
Compilation Error
Parse Error
Runtime Error
Test Failed

# In Python scripts
ERROR: Missing Snowflake credentials
ERROR: Failed to load report.json
ERROR: Could not analyze query complexity
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | [TODAY] | Initial validation framework complete |

---

**Status**: ✅ Ready for Execution

👉 **Next Action**: Set Snowflake credentials and run `bash run_pipeline.sh`

