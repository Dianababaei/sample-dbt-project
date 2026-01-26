#!/usr/bin/env python3
"""Compare baseline vs optimized reports using KPIs

Usage: python benchmark/compare_kpis.py
"""

import json
import os
import sys

def load_report(path):
    """Load a report JSON file"""
    if not os.path.exists(path):
        print(f"ERROR: {path} not found")
        return None
    with open(path) as f:
        return json.load(f)

def calculate_improvement(baseline, optimized, metric_path):
    """Calculate % improvement from baseline to optimized

    metric_path: list of keys to traverse, e.g. ['kpi_1_execution', 'runtime_seconds']
    """
    try:
        baseline_val = baseline
        optimized_val = optimized
        for key in metric_path:
            baseline_val = baseline_val[key]
            optimized_val = optimized_val[key]

        if baseline_val == 0:
            return None
        improvement = ((baseline_val - optimized_val) / baseline_val) * 100
        return improvement
    except Exception as e:
        return None

def main():
    baseline_path = "benchmark/baseline/report.json"
    candidate_path = "benchmark/candidate/report.json"

    print("=" * 70)
    print("Artemis Optimization Report - KPI Comparison")
    print("=" * 70)
    print()

    baseline = load_report(baseline_path)
    candidate = load_report(candidate_path)

    if not baseline or not candidate:
        print("ERROR: Missing baseline or candidate report")
        return 1

    # Extract KPIs
    baseline_meta = baseline['metadata']
    candidate_meta = candidate['metadata']

    print("KPI 1: EXECUTION TIME (Runtime)")
    print("-" * 70)
    baseline_runtime = baseline_meta['kpi_1_execution']['runtime_seconds']
    candidate_runtime = candidate_meta['kpi_1_execution']['runtime_seconds']
    improvement = calculate_improvement(baseline_meta, candidate_meta,
                                       ['kpi_1_execution', 'runtime_seconds'])

    print(f"  Baseline:  {baseline_runtime:.4f}s")
    print(f"  Optimized: {candidate_runtime:.4f}s")
    if improvement is not None:
        sign = "↓" if improvement > 0 else "↑"
        print(f"  Change:    {sign} {abs(improvement):.1f}%")
    print()

    print("KPI 2: WORK METRICS (Output Size)")
    print("-" * 70)
    baseline_rows = baseline_meta['kpi_2_work_metrics']['rows_returned']
    candidate_rows = candidate_meta['kpi_2_work_metrics']['rows_returned']
    improvement = calculate_improvement(baseline_meta, candidate_meta,
                                       ['kpi_2_work_metrics', 'rows_returned'])

    print(f"  Baseline:  {baseline_rows} rows")
    print(f"  Optimized: {candidate_rows} rows")
    if improvement is not None:
        sign = "↓" if improvement > 0 else "↑"
        print(f"  Change:    {sign} {abs(improvement):.1f}%")
    print()

    print("KPI 3: OUTPUT VALIDATION (Equivalence Check)")
    print("-" * 70)
    baseline_hash = baseline_meta['kpi_3_output_validation']['output_hash']
    candidate_hash = candidate_meta['kpi_3_output_validation']['output_hash']
    baseline_count = baseline_meta['kpi_3_output_validation']['row_count']
    candidate_count = candidate_meta['kpi_3_output_validation']['row_count']

    print(f"  Baseline hash:  {baseline_hash[:16]}...")
    print(f"  Optimized hash: {candidate_hash[:16]}...")
    print(f"  Baseline rows:  {baseline_count}")
    print(f"  Optimized rows: {candidate_count}")

    if baseline_hash == candidate_hash and baseline_count == candidate_count:
        print(f"  Status: ✅ IDENTICAL (output equivalence guaranteed)")
    else:
        print(f"  Status: ❌ DIFFERENT (output changed - optimization invalid)")
        return 1
    print()

    print("=" * 70)
    print("SUMMARY")
    print("=" * 70)

    # Only show improvements where applicable
    improvements = []

    runtime_improvement = calculate_improvement(baseline_meta, candidate_meta,
                                               ['kpi_1_execution', 'runtime_seconds'])
    if runtime_improvement is not None and runtime_improvement > 0:
        improvements.append(f"  • Runtime improved: {runtime_improvement:.1f}% faster")

    rows_improvement = calculate_improvement(baseline_meta, candidate_meta,
                                            ['kpi_2_work_metrics', 'rows_returned'])
    if rows_improvement is not None and rows_improvement > 0:
        improvements.append(f"  • Work reduced: {rows_improvement:.1f}% fewer rows processed")

    if baseline_hash == candidate_hash:
        improvements.append(f"  • Output validation: ✅ Guaranteed identical")

    if improvements:
        for imp in improvements:
            print(imp)
    else:
        print("  • No improvements detected")

    print()
    print("=" * 70)
    return 0

if __name__ == '__main__':
    sys.exit(main())
