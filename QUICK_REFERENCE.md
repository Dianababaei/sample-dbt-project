# Quick Reference: 5-KPI Benchmarking System

## TL;DR

✅ **All 5 KPIs are fully automatic**
✅ **Cost estimation is immediate** (no 15-45 min waiting)
✅ **Run once, get 5 metrics**

---

## The 5 KPIs

| # | Name | What | Score | Example |
|---|------|------|-------|---------|
| 1 | **Runtime** | Execution time | seconds | 4.5s vs 2.8s = ↓38% |
| 2 | **Work Metrics** | Bytes scanned | bytes | 100MB vs 50MB = ↓50% |
| 3 | **Output Hash** | Data integrity | SHA256 | ✅ Identical or ❌ Different |
| 4 | **Complexity** | Query structure | 1-10 | 7.5 vs 5.2 = ↓31% simpler |
| 5 | **Cost** | Credits estimated | credits | 0.000095 vs 0.000047 = ↓50% |

---

## Workflow

```
1. Artemis optimizes SQL files
2. Run: bash run_pipeline.sh
3. Run: python benchmark/compare_kpis.py
4. Review 5 KPI improvements
```

---

## Commands

```bash
# Generate candidate report with all 5 KPIs
bash run_pipeline.sh

# Compare baseline vs candidate across all 5 KPIs
python benchmark/compare_kpis.py
```

---

## Report Location

```
benchmark/
├── baseline/report.json      ← Golden truth
└── candidate/report.json     ← Latest run (auto-generated)
```

---

## Example Output

```
KPI 1: EXECUTION TIME
  Baseline:  4.5464s
  Optimized: 2.8100s
  Change:    ↓ 38.1%

KPI 2: WORK METRICS
  Baseline:  104,857,600 bytes
  Optimized: 52,428,800 bytes
  Change:    ↓ 50.0%

KPI 3: OUTPUT VALIDATION
  Status: ✅ IDENTICAL

KPI 4: QUERY COMPLEXITY
  Baseline:  7.5/10 (4 joins)
  Optimized: 5.2/10 (2 joins)
  Change:    ↓ 30.7% simpler

KPI 5: COST ESTIMATION
  Baseline:  0.00009537 credits
  Optimized: 0.00004768 credits
  Change:    ↓ 50.0% fewer credits
```

---

## Cost Calculation

```
1 credit = 1 TB of data scanned

credits = bytes_scanned / 1,099,511,627,776

Examples:
  50 MB  = 0.0000477 credits
  1 GB   = 0.00098 credits
  100 GB = 0.0977 credits
```

---

## Decision Matrix

```
IF output_hash_different THEN
  REJECT (data changed)

ELSE IF all_metrics_improved THEN
  ACCEPT (valid optimization)

ELSE IF some_metrics_worse THEN
  INVESTIGATE (trade-offs)
```

---

## Documentation Files

| File | Purpose |
|------|---------|
| `BENCHMARKING_GUIDE.md` | Step-by-step guide |
| `KPI_SYSTEM_EXPLAINED.md` | Technical deep dive |
| `IMPLEMENTATION_SUMMARY.md` | What changed & why |
| `QUICK_REFERENCE.md` | This file |

---

## Why This Works

- ✅ All automatic (no manual inspection)
- ✅ All immediate (no 15-45 min delay)
- ✅ All reliable (bytes_scanned from QUERY_PROFILE)
- ✅ All deterministic (same result every time)
- ✅ All auditable (metrics in JSON format)

---

## Key Features

### KPI 1: Runtime
- Measures wall-clock execution time
- Faster = less warehouse cost
- Immediate feedback

### KPI 2: Work Metrics
- Bytes scanned from Snowflake QUERY_PROFILE
- Direct proxy for credit cost
- No delay (unlike ACCOUNT_USAGE)

### KPI 3: Output Hash
- SHA256 of complete result set
- Cryptographically guarantees output didn't change
- Financial data protection

### KPI 4: Complexity
- Automatic SQL analysis (joins, CTEs, window functions)
- Complexity score 1-10
- Indicates query maintainability

### KPI 5: Cost
- Bytes scanned → credits conversion
- Immediate, reliable cost proxy
- No external system dependencies

---

## Files Modified

```
extract_report.py
  + analyze_query_complexity()
  + estimate_credits()
  + KPI 4 automatic analysis
  + KPI 5 cost calculation

benchmark/compare_kpis.py
  + KPI 4 comparison section
  + KPI 5 comparison section
  + Updated summary
```

---

## Testing Checklist

```
✅ KPI 1 captures runtime
✅ KPI 2 gets bytes from QUERY_PROFILE
✅ KPI 3 generates SHA256 hash
✅ KPI 4 analyzes SQL structure
✅ KPI 5 estimates credits
✅ Compare shows all 5 KPIs
✅ Hash validation works
✅ Improvement % calculated
```

---

## For Artemis Team

1. Optimize SQL files in `models/pipeline_a/`
2. Run: `bash run_pipeline.sh`
3. Run: `python benchmark/compare_kpis.py`
4. See improvement across 5 dimensions
5. Iterate until satisfied

**No waiting. All automatic. Immediate results.**
