#!/usr/bin/env python3
"""
Minimal benchmarking system: Compare baseline vs candidate

Rules (strict correctness-first):
  1. output_hash MUST be identical (same answers)
  2. row_count MUST be equal (same data)
  3. runtime_seconds MUST be <= baseline (faster or equal)

Exit codes:
  0 = PASS (all rules met)
  1 = FAIL (any rule broken)
"""

import json
import sys
import os

def load_report(path):
    """Load a report JSON file"""
    if not os.path.exists(path):
        return None
    try:
        with open(path) as f:
            return json.load(f)
    except Exception as e:
        print(f"ERROR: Failed to load {path}: {e}")
        return None

def main():
    baseline_path = "benchmark/baseline/report.json"
    candidate_path = "benchmark/candidate/report.json"

    # Load reports
    baseline = load_report(baseline_path)
    candidate = load_report(candidate_path)

    if not baseline or not candidate:
        print("FAIL: Missing baseline or candidate report")
        return 1

    baseline_meta = baseline.get('metadata', {})
    candidate_meta = candidate.get('metadata', {})

    # Rule 1: output_hash MUST be identical
    baseline_hash = baseline_meta.get('kpi_3_output_validation', {}).get('output_hash')
    candidate_hash = candidate_meta.get('kpi_3_output_validation', {}).get('output_hash')

    if not baseline_hash or not candidate_hash:
        print("FAIL: Missing output hash")
        return 1

    if baseline_hash != candidate_hash:
        print("FAIL: Output hash mismatch (answers are different)")
        print(f"  Baseline:  {baseline_hash[:16]}...")
        print(f"  Candidate: {candidate_hash[:16]}...")
        return 1

    # Rule 2: row_count MUST be equal
    baseline_rows = baseline_meta.get('kpi_3_output_validation', {}).get('row_count')
    candidate_rows = candidate_meta.get('kpi_3_output_validation', {}).get('row_count')

    if baseline_rows != candidate_rows:
        print("FAIL: Row count mismatch")
        print(f"  Baseline:  {baseline_rows} rows")
        print(f"  Candidate: {candidate_rows} rows")
        return 1

    # Rule 3: runtime_seconds MUST be <= baseline
    baseline_runtime = baseline_meta.get('kpi_1_execution', {}).get('runtime_seconds')
    candidate_runtime = candidate_meta.get('kpi_1_execution', {}).get('runtime_seconds')

    if baseline_runtime is None or candidate_runtime is None:
        print("FAIL: Missing runtime data")
        return 1

    if candidate_runtime > baseline_runtime:
        print("FAIL: Slower than baseline")
        print(f"  Baseline:  {baseline_runtime:.4f}s")
        print(f"  Candidate: {candidate_runtime:.4f}s")
        return 1

    # All rules passed - print summary
    runtime_delta = candidate_runtime - baseline_runtime
    runtime_pct = (runtime_delta / baseline_runtime * 100) if baseline_runtime > 0 else 0

    print("PASS: Benchmark successful")
    print(f"  Same answers:   {baseline_hash[:16]}...")
    print(f"  Same rows:      {baseline_rows}")
    print(f"  Faster runtime: {baseline_runtime:.4f}s -> {candidate_runtime:.4f}s ({runtime_pct:+.1f}%)")

    return 0

if __name__ == '__main__':
    sys.exit(main())
