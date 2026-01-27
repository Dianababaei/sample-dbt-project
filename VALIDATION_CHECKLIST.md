# Validation Execution Checklist

## Pre-Execution Setup

### Environment Configuration
- [ ] Snowflake account credentials configured
  - `export SNOWFLAKE_ACCOUNT="your_account_id"`
  - `export SNOWFLAKE_USER="your_username"`
  - `export SNOWFLAKE_PASSWORD="your_password"`
- [ ] Snowflake Python connector installed: `pip install snowflake-connector-python`
- [ ] dbt installed: `pip install dbt-snowflake`
- [ ] Python 3.8+ available in PATH

### Project State
- [ ] No uncommitted changes in models/pipeline_a/
- [ ] run_pipeline.sh is executable: `chmod +x run_pipeline.sh`
- [ ] extract_report.py is executable: `chmod +x extract_report.py`
- [ ] benchmark/compare.py is executable: `chmod +x benchmark/compare.py`
- [ ] benchmark/compare_kpis.py is executable: `chmod +x benchmark/compare_kpis.py`
- [ ] benchmark/baseline/report.json exists and is readable

---

## Execution Phase

### Step 1: Run Optimized Pipeline
```bash
bash run_pipeline.sh
```

**Expected Output**:
```
==========================================
🚀 dbt Pipeline - Clean Execution
==========================================

📦 Installing dbt packages...
✅ Done

📊 Loading seed data...
✅ Done

🏗️  Building models...
✅ Done

🧪 Running tests...
✅ Done

Generating report from Snowflake...
[OK] Report generated:
     - Rows: 426
     - Runtime: X.XXXXs
     - Complexity Score: X/10
     - Estimated Credits: 0.XXXXXX
     - Output Hash: 4ae5e137...

Running benchmark comparison...
PASS: Benchmark successful
  Same answers:   4ae5e137...
  Same rows:      426
  Faster runtime: 4.5319s -> X.XXXXs (Y.Y%)

==========================================
[OK] Pipeline Complete!
==========================================
```

**Exit Code Check**:
- [ ] Exit code is 0 (success)
  ```bash
  echo $?  # Should print: 0
  ```

### Step 2: Verify Candidate Report Generated
```bash
ls -lh benchmark/candidate/report.json
```

**Expected**:
- [ ] File exists and is readable
- [ ] File size > 50KB (contains full data output)
- [ ] Recent modification time (just now)

### Step 3: Review Baseline vs Candidate

**Critical Validation 1: Output Hash Match**
```bash
python3 -c "
import json
with open('benchmark/baseline/report.json') as f:
    baseline = json.load(f)
with open('benchmark/candidate/report.json') as f:
    candidate = json.load(f)

baseline_hash = baseline['metadata']['kpi_3_output_validation']['output_hash']
candidate_hash = candidate['metadata']['kpi_3_output_validation']['output_hash']

print(f'Baseline Hash:  {baseline_hash}')
print(f'Candidate Hash: {candidate_hash}')
print(f'Match: {baseline_hash == candidate_hash} ✓' if baseline_hash == candidate_hash else f'Match: {baseline_hash == candidate_hash} ✗')
"
```

**Expected Result**:
- [ ] Both hashes are identical
- [ ] Hash value: `4ae5e137a8fb74272f61f38fac934d793da5b1e81fd79be573c55b29f7bdf08e`
- Status: ✅ PASS (MUST MATCH)

**Critical Validation 2: Row Count Match**
```bash
python3 -c "
import json
with open('benchmark/baseline/report.json') as f:
    baseline = json.load(f)
with open('benchmark/candidate/report.json') as f:
    candidate = json.load(f)

baseline_rows = baseline['metadata']['kpi_3_output_validation']['row_count']
candidate_rows = candidate['metadata']['kpi_3_output_validation']['row_count']

print(f'Baseline Rows:  {baseline_rows}')
print(f'Candidate Rows: {candidate_rows}')
print(f'Match: {baseline_rows == candidate_rows} ✓' if baseline_rows == candidate_rows else f'Match: {baseline_rows == candidate_rows} ✗')
"
```

**Expected Result**:
- [ ] Both row counts are identical
- [ ] Value: `426 rows`
- Status: ✅ PASS (MUST MATCH)

**Critical Validation 3: Runtime Improvement**
```bash
python3 -c "
import json
with open('benchmark/baseline/report.json') as f:
    baseline = json.load(f)
with open('benchmark/candidate/report.json') as f:
    candidate = json.load(f)

baseline_runtime = baseline['metadata']['kpi_1_execution']['runtime_seconds']
candidate_runtime = candidate['metadata']['kpi_1_execution']['runtime_seconds']
improvement = ((baseline_runtime - candidate_runtime) / baseline_runtime) * 100

print(f'Baseline Runtime:  {baseline_runtime:.4f}s')
print(f'Candidate Runtime: {candidate_runtime:.4f}s')
print(f'Improvement:       {improvement:.1f}%')
print(f'Target:            < 4.5319s')
print(f'Pass: {candidate_runtime < baseline_runtime} ✓' if candidate_runtime < baseline_runtime else f'Pass: {candidate_runtime < baseline_runtime} ✗')
"
```

**Expected Result**:
- [ ] Candidate runtime < 4.5319 seconds
- [ ] Performance improvement > 0% (ideally 15-25%)
- Status: ✅ PASS (MUST IMPROVE)

### Step 4: Run Detailed Comparison
```bash
python benchmark/compare_kpis.py
```

**Expected Output Structure**:

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
  Change:    DOWN 0.0%

KPI 3: OUTPUT VALIDATION (Equivalence Check)
----------------------------------------------------------------------
  Baseline hash:  4ae5e137...
  Optimized hash: 4ae5e137...
  Baseline rows:  426
  Optimized rows: 426
  Status: [OK] IDENTICAL (output equivalence guaranteed)

KPI 4: QUERY COMPLEXITY (Structure Analysis)
----------------------------------------------------------------------
  Baseline complexity:  5.0/10 (1 joins)
  Optimized complexity: X.X/10 (1 joins)
  Change:              X.X% simpler

KPI 5: COST ESTIMATION (Bytes Scanned -> Credits)
----------------------------------------------------------------------
  Baseline:  0.302125 credits (436224 bytes)
  Optimized: X.XXXXXX credits (XXXXXX bytes)
  Change:    DOWN X.X% fewer credits

======================================================================
SUMMARY
======================================================================
  • Runtime improved: X.X% faster
  • Output validation: [OK] Guaranteed identical
  • Cost reduced: X.X% fewer credits
```

**Validation Checkpoints**:
- [ ] KPI 1: Positive % improvement shown (DOWN X.X%)
- [ ] KPI 2: Row count unchanged (426 rows)
- [ ] KPI 3: Output validation status [OK] IDENTICAL
- [ ] KPI 4: Complexity score maintained or improved
- [ ] KPI 5: Cost reduction documented

### Step 5: Document Results

#### Runtime Improvement
- [ ] Calculate actual improvement: `((4.5319 - X.XXXX) / 4.5319) * 100`
- [ ] Expected: 15-25% improvement
- [ ] Record actual value: _____ %

#### Cost Savings
- [ ] Calculate credit savings: `((0.302125 - X.XXXXXX) / 0.302125) * 100`
- [ ] Expected: 15-25% reduction
- [ ] Record actual value: _____ %

#### Bytes Scanned Reduction
- [ ] Calculate bytes saved: `((436224 - XXXXXX) / 436224) * 100`
- [ ] Expected: 10-20% reduction
- [ ] Record actual value: _____ %

---

## Data Quality Validation

### dbt Test Results
```bash
grep -E "^(PASSED|FAILED)" logs/dbt.log | tail -20
```

**Expected**:
- [ ] All 65 tests PASSED
- [ ] No tests FAILED or ERROR
- [ ] Tests include:
  - Unique constraints (11 tests)
  - Not-null constraints (28 tests)
  - Referential integrity (12 tests)
  - Business logic (14 tests)

---

## Success/Failure Criteria

### ✅ VALIDATION PASSED (All Three MUST Conditions Met)

**If you see**:
```
✓ Output Hash: 4ae5e137a8fb74272f61f38fac934d793da5b1e81fd79be573c55b29f7bdf08e (MATCH)
✓ Row Count: 426 (MATCH)
✓ Runtime: X.XXXXs < 4.5319s (IMPROVEMENT)
```

**Then**:
- [ ] Optimization ACCEPTED
- [ ] Performance gains documented
- [ ] All tests passing
- [ ] Ready for deployment

**Document**:
- [ ] Runtime reduction: X.X%
- [ ] Cost savings: X.X%
- [ ] Data quality: All 65 tests passed

---

### ❌ VALIDATION FAILED (Debug Needed)

#### Scenario 1: Hash Mismatch
```
✗ Output Hash Mismatch: 4ae5e137... != [DIFFERENT HASH]
```

**Action**:
- [ ] Review fact_cashflow_summary.sql aggregation logic
- [ ] Check for business logic changes
- [ ] Verify no data is lost or duplicated
- [ ] Run: `SELECT COUNT(*), COUNT(DISTINCT cashflow_summary_key) FROM FACT_CASHFLOW_SUMMARY`
- [ ] Roll back changes and try different approach

#### Scenario 2: Row Count Mismatch
```
✗ Row Count Mismatch: 426 != [DIFFERENT_COUNT]
```

**Action**:
- [ ] Review WHERE clauses in all models
- [ ] Check JOIN logic (INNER vs LEFT)
- [ ] Verify GROUP BY columns in aggregation
- [ ] Run: `SELECT COUNT(*) FROM FACT_CASHFLOW_SUMMARY`
- [ ] Compare with baseline count

#### Scenario 3: No Performance Improvement
```
✗ Runtime Not Improved: X.XXXXs >= 4.5319s
```

**Action**:
- [ ] Check Snowflake query profile for slow steps
- [ ] Verify pre-aggregation actually reduced rows
- [ ] Look for full table scans in execution plan
- [ ] Consider alternative optimization
- [ ] Document finding for next iteration

---

## Post-Validation Steps

### 1. Archive Results
```bash
cp benchmark/candidate/report.json benchmark/archive/report_$(date +%Y%m%d_%H%M%S).json
```

### 2. Update Documentation
- [ ] Add actual improvement numbers to VALIDATION_RESULTS.md
- [ ] Update performance benchmarks
- [ ] Document any findings or issues

### 3. Commit Changes (if successful)
```bash
git add models/pipeline_a/
git add VALIDATION_RESULTS.md
git commit -m "Task 3: Validate SQL optimizations - ✓ PASSED with X.X% improvement"
```

### 4. Move to Next Task
- [ ] Task 4: Run full test suite and verify data quality

---

## Troubleshooting Guide

### Issue: "Snowflake credentials not set"
**Solution**:
```bash
export SNOWFLAKE_ACCOUNT="your_account"
export SNOWFLAKE_USER="your_user"
export SNOWFLAKE_PASSWORD="your_password"
```

### Issue: "snowflake-connector-python not installed"
**Solution**:
```bash
pip install snowflake-connector-python
```

### Issue: "dbt deps fails"
**Solution**:
```bash
rm -rf dbt_packages/
dbt deps --upgrade
```

### Issue: "Permission denied" on .sh files
**Solution**:
```bash
chmod +x run_pipeline.sh extract_report.py artemis_run.sh
```

### Issue: "Cannot connect to Snowflake"
**Solution**:
- Verify credentials are correct
- Check network connectivity
- Verify COMPUTE_WH warehouse exists and is running
- Verify user has appropriate role/permissions

---

## Summary

**Total Validation Checkpoints**: 15
**Required PASS Conditions**: 3 (hash, row count, runtime)
**Expected Execution Time**: 3-5 minutes
**Success Criteria**: All 3 MUST conditions pass + all 65 tests pass

**Next Action**: Execute `bash run_pipeline.sh` and work through checklist above.
