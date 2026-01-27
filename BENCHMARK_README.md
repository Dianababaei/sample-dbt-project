# Benchmarking System

Simple, deterministic benchmarking to measure optimization impact.

## Overview

Compares a **fixed baseline** (golden truth) against **latest candidate** (current run).

**Goal:** Same answers, faster execution.

## Folder Structure

```
benchmark/
├── baseline/report.json       (created once, never overwritten)
├── candidate/report.json      (overwritten on each run)
└── compare.py                 (benchmark logic)
```

## How It Works

### 1. Baseline (One-Time Setup)

First run establishes the baseline:

```bash
# Set Snowflake credentials
export SNOWFLAKE_ACCOUNT=IUTIMNF-LNB78386
export SNOWFLAKE_USER=diana
export SNOWFLAKE_PASSWORD='your_password'

# Run pipeline to generate baseline
bash run_pipeline.sh

# Copy candidate to baseline
cp benchmark/candidate/report.json benchmark/baseline/report.json
```

Now `benchmark/baseline/report.json` is your golden truth.

### 2. Optimize & Compare

Modify SQL files, then run:

```bash
bash run_pipeline.sh
```

This automatically:
1. Runs dbt pipeline
2. Generates `benchmark/candidate/report.json`
3. Runs `python benchmark/compare.py`
4. **Fails if any rule is broken**

## Benchmark Rules

**Rule 1: Same Answers**
- `output_hash` MUST be identical
- If hashes differ → optimization changed the result → FAIL

**Rule 2: Same Data**
- `row_count` MUST be equal to baseline
- If rows differ → data changed → FAIL

**Rule 3: Faster Execution**
- `runtime_seconds` MUST be <= baseline
- If slower → doesn't meet requirements → FAIL

## Example Output

### PASS (Optimization Successful)

```
PASS: Benchmark successful
  Same answers:   7bcdd71ce8b45f11...
  Same rows:      49
  Faster runtime: 2.0267s -> 1.5200s (-24.9%)
```

Exit code: `0` (pipeline continues)

### FAIL (Optimization Invalid)

```
FAIL: Output hash mismatch (answers are different)
  Baseline:  7bcdd71ce8b45f11...
  Candidate: a1b2c3d4e5f6a1b2...
```

Exit code: `1` (pipeline stops)

## Report Format

### benchmark/baseline/report.json

```json
{
  "metadata": {
    "kpi_1_execution": {
      "runtime_seconds": 2.0267
    },
    "kpi_3_output_validation": {
      "row_count": 49,
      "output_hash": "7bcdd71ce8b45f..."
    }
  },
  "data": [...]
}
```

## Workflow

```
SQL Optimization
    ↓
bash run_pipeline.sh
    ├─ dbt deps, seed, run, test
    ├─ extract_report.py (generates candidate)
    ├─ compare.py (checks rules)
    └─ Exit code 0 (PASS) or 1 (FAIL)
```

## Key Features

✅ **Minimal:** Only 3 rules, ~100 lines of code

✅ **Strict:** Hash equality gates all improvements

✅ **Deterministic:** Same input → same result always

✅ **Fast:** Comparison runs in < 1 second

✅ **Embedded:** Lives in repo, no external dependencies

## Common Tasks

### Reset Baseline to Current Metrics

```bash
cp benchmark/candidate/report.json benchmark/baseline/report.json
```

### View Baseline Metrics

```bash
cat benchmark/baseline/report.json | python -m json.tool
```

### View Candidate Metrics

```bash
cat benchmark/candidate/report.json | python -m json.tool
```

### Run Benchmark Manually

```bash
python benchmark/compare.py
```

## Next Steps for Artemis

1. **Baseline is set** ✓
2. Artemis optimizes SQL in `models/pipeline_a/`
3. Run `bash run_pipeline.sh`
4. Check benchmark result
5. If PASS: Metric improved, keep changes
6. If FAIL: Output changed, revert or investigate
7. Repeat until optimization goal met

---

**Goal:** Same correct answers, less time.
