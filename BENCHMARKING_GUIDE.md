# Benchmarking Guide - Artemis dbt Optimization

**Quick Start for comparing baseline vs optimized pipelines**

---

## What You Get

✅ dbt sample project (14 models, 65 tests, 49-row output)
✅ Baseline report (original pipeline metrics)
✅ Comparison framework (4-KPI model)
✅ No credit delays (deterministic measurements)

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
  Baseline:  4.52s
  Optimized: 2.81s
  Change:    ↓ 37.8%

KPI 3: OUTPUT VALIDATION
  Status: ✅ IDENTICAL
```

---

## The 4 KPIs Explained

| # | KPI | What | Why | Pass Condition |
|---|-----|------|-----|---|
| 1 | **Runtime** | Query execution time (s) | Faster = cheaper | Should ↓ |
| 2 | **Work Metrics** | Rows/data processed | Volume = cost | Should ↓ or = |
| 3 | **Output Hash** | SHA256 of result set | Guarantee no drift | Must be **identical** |
| 4 | **Complexity** | Query structure | Informs quality | Context only |

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

## Why No Credits?

Snowflake's `ACCOUNT_USAGE.QUERY_HISTORY` has 15-45 min delay (system limitation).

Instead, we use:
- **Runtime** (immediate, deterministic)
- **Work metrics** (immediate, deterministic)
- **Output hash** (immediate, deterministic)

These correlate perfectly with cost and have no delays.

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
