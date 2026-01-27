# Benchmarking Guide - Artemis dbt Optimization

**Quick Start for comparing baseline vs optimized pipelines**

---

## What You Get

✅ dbt sample project (14 models, 65 tests, 49-row output)
✅ Baseline report (original pipeline metrics)
✅ Comparison framework (5-KPI model, all automatic)
✅ Immediate cost estimation (bytes scanned → credits, no 15-45 min delays)

---

## The 3 Steps

### 1️⃣ Baseline (Original Code)

Already done. Located at:
```
benchmark/baseline/report.json
```

Contains:
- Runtime: 4.52 seconds
- Output: 49 rows, hash = `b006f42b...`

---

### 2️⃣ Optimize

Artemis modifies SQL files in:
```
models/pipeline_a/marts/fact_cashflow_summary.sql
models/pipeline_a/staging/stg_cashflows.sql
```

---

### 3️⃣ Compare

Run:
```bash
bash run_pipeline.sh
python benchmark/compare_kpis.py
```

**Output:**
```
KPI 1: EXECUTION TIME
  Baseline:  4.5464s
  Optimized: 2.8100s
  Change:    ↓ 38.1%

KPI 2: WORK METRICS
  Baseline:  104857600 bytes (100 MB)
  Optimized: 52428800 bytes (50 MB)
  Change:    ↓ 50.0%

KPI 3: OUTPUT VALIDATION
  Status: ✅ IDENTICAL (guaranteed no data drift)

KPI 4: QUERY COMPLEXITY
  Baseline:  7.5/10 (4 joins, 2 CTEs)
  Optimized: 5.2/10 (2 joins, 1 CTE)
  Change:    ↓ 30.7% simpler

KPI 5: COST ESTIMATION
  Baseline:  0.0001 credits (100 MB scanned)
  Optimized: 0.00005 credits (50 MB scanned)
  Change:    ↓ 50.0% fewer credits
```

---

## The 5 KPIs Explained (All Automatic)

| # | KPI | What | Why | Pass Condition |
|---|-----|------|-----|---|
| 1 | **Runtime** | Query execution time (s) | Faster = cheaper | Should ↓ |
| 2 | **Work Metrics** | Bytes scanned from QUERY_PROFILE | Direct cost proxy | Should ↓ or = |
| 3 | **Output Hash** | SHA256 of result set | Guarantee no drift | Must be **identical** |
| 4 | **Complexity** | Query structure analysis (joins, CTEs, window functions) | Automatic scoring 1-10 | Should ↓ or = |
| 5 | **Cost Estimation** | Credits estimated from bytes scanned (1 credit = 1 TB) | Reliable cost proxy, no waiting | Should ↓ or = |

---

## Interpreting Results

### ✅ Good Optimization
- Runtime ↓ 30-50%
- Rows = same
- Hash ✅ identical
- **Decision: ACCEPT**

### ❌ Invalid Optimization
- Hash ❌ different
- Numbers changed
- **Decision: REJECT** (breaks financial reporting)

### ⚠️ Suspicious Optimization
- Runtime ↓ but hash changed
- **Decision: INVESTIGATE** (did logic change intentionally?)

---

## File Structure

```
benchmark/
├── baseline/
│   └── report.json          ← Original metrics (golden truth)
├── candidate/
│   └── report.json          ← Current metrics (generated each run)
├── compare_kpis.py          ← Comparison script
├── KPI_BENCHMARKING.md      ← Detailed KPI docs
└── README.md                ← Generic benchmark framework
```

---

## One Command

```bash
bash run_pipeline.sh && python benchmark/compare_kpis.py
```

---

## Why This Framework Works

Snowflake's `ACCOUNT_USAGE.QUERY_HISTORY` has 15-45 min delay (system limitation), making credit-based benchmarking non-viable for rapid iteration.

Instead, we use **immediate, deterministic metrics**:
- **Runtime** - Wall-clock execution time (immediate)
- **Work Metrics** - Bytes scanned from QUERY_PROFILE (immediate, available right after query)
- **Output Hash** - SHA256 of result set (immediate, cryptographic guarantee)
- **Complexity Score** - Automatic query structure analysis (immediate)
- **Cost Estimation** - Bytes scanned → credits calculation (immediate, no delays)

All KPIs are:
- ✅ Automatic (no manual inspection)
- ✅ Deterministic (same result every time)
- ✅ Immediate (available the moment the query finishes)
- ✅ Reliable (bytes scanned directly correlates with Snowflake cost)
- ✅ No external dependencies (don't rely on delayed billing systems)

---

## Next Steps

1. ✅ Original pipeline ready
2. 🔄 Artemis optimizes SQL
3. ✅ Run `bash run_pipeline.sh`
4. ✅ Compare with `python benchmark/compare_kpis.py`
5. 📊 Show results to Bain Capital

---

## For Technical Details

See: `benchmark/KPI_BENCHMARKING.md`
