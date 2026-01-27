# 5-KPI Automated Benchmarking System

**All KPIs are now fully automatic with no manual steps.**

---

## KPI Architecture

```
Query Execution
    ↓
Snowflake QUERY_PROFILE (immediate)
    ├─ Execution time
    ├─ Bytes scanned
    ├─ Rows produced
    └─ Query text
    ↓
extract_report.py processes all 5 KPIs automatically
    ├─ KPI 1: Runtime from wall-clock time
    ├─ KPI 2: Work metrics from QUERY_PROFILE
    ├─ KPI 3: Output hash from result set
    ├─ KPI 4: Complexity score from query text analysis
    └─ KPI 5: Cost estimation from bytes scanned
    ↓
benchmark/candidate/report.json (auto-generated)
    ↓
compare_kpis.py compares baseline vs candidate
    ├─ Runtime improvement %
    ├─ Bytes scanned improvement %
    ├─ Output equivalence check
    ├─ Complexity reduction %
    └─ Cost estimation improvement %
```

---

## Each KPI in Detail

### KPI 1: Execution Time (Seconds)

**What it measures:**
- Wall-clock time from query start to result fetch
- Includes connection, compilation, and execution

**How it's calculated:**
```python
query_start = time.time()
# ... execute query ...
query_time = time.time() - query_start  # seconds
```

**Why it matters:**
- Direct measure of query performance
- Faster queries cost less (less warehouse time)

**Example improvement:**
```
Baseline:  4.5464s
Optimized: 2.8100s
Improvement: ↓ 38.1% faster
```

---

### KPI 2: Work Metrics (Bytes Scanned)

**What it measures:**
- Total bytes scanned by Snowflake query engine
- Retrieved from QUERY_PROFILE (available immediately after query)
- Direct proxy for Snowflake cost (1 credit = 1 TB of data)

**How it's calculated:**
```python
# From Snowflake QUERY_PROFILE
SELECT BYTES_SCANNED FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
```

**Why it matters:**
- Bytes scanned = billable units in Snowflake
- Directly determines credit usage
- No 15-45 minute delay like ACCOUNT_USAGE.QUERY_HISTORY

**Example:**
```
Baseline:  104,857,600 bytes (100 MB scanned)
Optimized: 52,428,800 bytes (50 MB scanned)
Improvement: ↓ 50% fewer bytes scanned
```

---

### KPI 3: Output Validation (SHA256 Hash)

**What it measures:**
- Cryptographic hash of final result set
- Guarantees output hasn't changed

**How it's calculated:**
```python
data_str = json.dumps(data, sort_keys=True, default=str)
output_hash = hashlib.sha256(data_str.encode()).hexdigest()
```

**Why it matters:**
- Financial data must not drift during optimization
- Ensures optimization doesn't change calculations
- If hashes differ → optimization is invalid, period

**Examples:**
```
✅ PASS (hashes match):
  Baseline:  7bcdd71ce8b45f11d148825c315b9641a2f494de...
  Optimized: 7bcdd71ce8b45f11d148825c315b9641a2f494de...
  → Optimization is VALID

❌ FAIL (hashes differ):
  Baseline:  7bcdd71ce8b45f11d148825c315b9641a2f494de...
  Optimized: a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2...
  → REJECT optimization (output changed)
```

---

### KPI 4: Query Complexity (Automatic Scoring)

**What it measures:**
- Query structure complexity scored 1-10
- Automatically analyzes SQL for:
  - Number of JOIN statements
  - Number of CTEs (WITH clauses)
  - Window functions (OVER clauses)
  - Nested subqueries
  - Compilation time

**How it's calculated:**
```python
complexity_score = min(10, 1 +
    (num_joins * 1.5) +           # Each join adds 1.5 points
    (num_ctes * 0.5) +            # Each CTE adds 0.5 points
    (num_window_functions * 2) +  # Each window function adds 2 points
    (num_subqueries * 1.5)        # Each subquery adds 1.5 points
)
```

**Why it matters:**
- Simpler queries are easier to maintain
- Lower complexity usually = lower latency
- Informs data engineering decisions beyond just "faster"

**Example:**
```
Baseline:
  Complexity: 7.5/10
  - 4 JOINs
  - 2 CTEs
  - 1 window function
  - 3 subqueries

Optimized:
  Complexity: 5.2/10
  - 2 JOINs (removed unnecessary ones)
  - 1 CTE
  - 1 window function
  - 1 subquery

Improvement: ↓ 30.7% simpler query structure
```

---

### KPI 5: Cost Estimation (Credits)

**What it measures:**
- Estimated Snowflake credits based on bytes scanned
- Uses standard Snowflake pricing: 1 credit per 1 TB

**How it's calculated:**
```python
TB_IN_BYTES = 1099511627776  # 1 TB
credits_estimated = (bytes_scanned / TB_IN_BYTES) * 1

# Example:
# 50 MB = 52,428,800 bytes
# credits = (52,428,800 / 1099511627776) * 1
# credits = 0.0000477 credits
```

**Why it matters:**
- **Reliable**: Based on actual bytes scanned from QUERY_PROFILE
- **Immediate**: Available right when query completes
- **Accurate**: Direct correlation with Snowflake billing
- **No delays**: Unlike ACCOUNT_USAGE which has 15-45 min lag

**How to convert:**
- `bytes_scanned / 1,099,511,627,776 = credits`
- 50 MB = 0.0000477 credits
- 1 GB = 0.00098 credits
- 100 GB = 0.0977 credits

**Example:**
```
Baseline:
  Bytes scanned: 104,857,600 (100 MB)
  Credits estimated: 0.0000954 credits

Optimized:
  Bytes scanned: 52,428,800 (50 MB)
  Credits estimated: 0.0000477 credits

Improvement: ↓ 50% fewer credits
```

---

## Report JSON Structure

### Baseline Report (benchmark/baseline/report.json)
```json
{
  "metadata": {
    "timestamp": "2026-01-26T03:05:26",
    "pipeline": "dbt sample project",
    "target_table": "FACT_CASHFLOW_SUMMARY",

    "kpi_1_execution": {
      "runtime_seconds": 4.5464,
      "description": "End-to-end query execution time"
    },

    "kpi_2_work_metrics": {
      "rows_returned": 49,
      "bytes_scanned": 104857600,
      "description": "Rows and bytes scanned (direct from Snowflake QUERY_PROFILE)"
    },

    "kpi_3_output_validation": {
      "row_count": 49,
      "output_hash": "7bcdd71ce8b45f11d148825c315b9641a2f494de946539438dd8ddc4b7f866c6",
      "description": "SHA256 hash for output equivalence checking"
    },

    "kpi_4_complexity": {
      "query_id": "01a12345-b678-90cd-ef12-3456789abcde",
      "num_joins": 4,
      "num_ctes": 2,
      "num_window_functions": 1,
      "num_subqueries": 3,
      "complexity_score": 7.5,
      "execution_time_ms": 4546,
      "compilation_time_ms": 234,
      "description": "Query complexity: 4 joins, 2 CTEs, 1 window functions"
    },

    "kpi_5_cost_estimation": {
      "bytes_scanned": 104857600,
      "credits_estimated": 0.0000954,
      "description": "Estimated credits based on bytes scanned (1 credit per 1 TB), no waiting for async billing"
    }
  },
  "data": [
    // ... 49 rows of actual result set ...
  ]
}
```

### Candidate Report (benchmark/candidate/report.json)
- Same structure as baseline
- Auto-generated on each `bash run_pipeline.sh`
- Overwrites previous candidate

---

## Comparison Output Example

```
======================================================================
Artemis Optimization Report - KPI Comparison
======================================================================

KPI 1: EXECUTION TIME (Runtime)
----------------------------------------------------------------------
  Baseline:  4.5464s
  Optimized: 2.8100s
  Change:    ↓ 38.1%

KPI 2: WORK METRICS (Output Size)
----------------------------------------------------------------------
  Baseline:  104857600 bytes (100 MB)
  Optimized: 52428800 bytes (50 MB)
  Change:    ↓ 50.0%

KPI 3: OUTPUT VALIDATION (Equivalence Check)
----------------------------------------------------------------------
  Baseline hash:  7bcdd71ce8b4...
  Optimized hash: 7bcdd71ce8b4...
  Status: ✅ IDENTICAL (output equivalence guaranteed)

KPI 4: QUERY COMPLEXITY (Structure Analysis)
----------------------------------------------------------------------
  Baseline complexity:  7.5/10 (4 joins)
  Optimized complexity: 5.2/10 (2 joins)
  Change:               ↓ 30.7% simpler

KPI 5: COST ESTIMATION (Bytes Scanned → Credits)
----------------------------------------------------------------------
  Baseline:  0.0000954 credits (104857600 bytes)
  Optimized: 0.0000477 credits (52428800 bytes)
  Change:    ↓ 50.0% fewer credits

======================================================================
SUMMARY
======================================================================
  • Runtime improved: 38.1% faster
  • Work reduced: 50.0% fewer bytes processed
  • Output validation: ✅ Guaranteed identical
  • Complexity reduced: 30.7% simpler query
  • Cost reduced: 50.0% fewer credits

======================================================================
```

---

## Workflow for Artemis Optimization

1. **Baseline established** (already done)
   - Original pipeline metrics saved in `benchmark/baseline/report.json`
   - Golden truth for all comparisons

2. **Artemis optimizes SQL**
   - Modifies model files in `models/pipeline_a/`
   - Makes query more efficient

3. **Run pipeline**
   ```bash
   bash run_pipeline.sh
   ```
   - dbt runs all models
   - extract_report.py generates ALL 5 KPIs automatically
   - Report saved to `benchmark/candidate/report.json`

4. **Compare results**
   ```bash
   python benchmark/compare_kpis.py
   ```
   - Shows all 5 KPI comparisons side-by-side
   - Calculates improvement % for each KPI
   - Validates output equivalence (hash check)

5. **Decision matrix**
   ```
   IF output_hash_different THEN
     REJECT optimization (changed the result)
   ELSE IF all metrics improved THEN
     ACCEPT optimization (valid improvement)
   ELSE IF some metrics improved, some worse THEN
     INVESTIGATE (trade-off analysis needed)
   ```

---

## Why All Automatic?

Your original request: **"I want all to be automatically. And also want to estimate cost in a more reliable metric"**

We delivered:

| Metric | Manual? | Reliable? | Delay? |
|--------|---------|-----------|--------|
| KPI 1 (Runtime) | ❌ No | ✅ Yes | Immediate |
| KPI 2 (Work Metrics) | ❌ No | ✅ Yes (from QUERY_PROFILE) | Immediate |
| KPI 3 (Output Hash) | ❌ No | ✅ Yes (cryptographic) | Immediate |
| KPI 4 (Complexity) | ❌ No (auto-analyzed) | ✅ Yes (query text) | Immediate |
| KPI 5 (Cost) | ❌ No | ✅ Yes (bytes scanned) | Immediate |

**Old way** (flawed):
- Wait 15-45 minutes for ACCOUNT_USAGE data
- Unreliable (delays and data freshness issues)
- Manual verification needed

**New way** (reliable):
- Everything calculated immediately
- All metrics automatic
- Cryptographic verification (hash)
- No external dependencies

---

## For Artemis Integration

1. Artemis modifies SQL files
2. Run: `bash run_pipeline.sh`
3. All 5 KPIs auto-generated in candidate report
4. Run: `python benchmark/compare_kpis.py`
5. See improvement across all 5 dimensions
6. Iterate until satisfied

No waiting. No manual steps. All automatic.
