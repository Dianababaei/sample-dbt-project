#!/usr/bin/env python3
"""
Validation benchmark script for Pipeline C optimizations
Simulates the benchmark execution and validates results
"""

import json
import sys
import os
from pathlib import Path

def load_report(path):
    """Load a JSON report"""
    try:
        with open(path, 'r') as f:
            return json.load(f)
    except Exception as e:
        print(f"Error loading report from {path}: {e}")
        return None

def main():
    """Main validation flow - load and compare reports"""
    print("\n" + "="*60)
    print("PIPELINE C OPTIMIZATION VALIDATION")
    print("="*60)
    
    # Check baseline report
    print("\n[STEP 1] Loading baseline report...")
    baseline_path = Path("benchmark/pipeline_c/baseline/report.json")
    
    if not baseline_path.exists():
        print(f"✗ Baseline report not found at {baseline_path}")
        return 1
    
    baseline = load_report(baseline_path)
    if not baseline:
        return 1
    
    print(f"✓ Baseline report loaded")
    
    # Check for optimized report (may not exist yet)
    print("\n[STEP 2] Checking for optimized report...")
    optimized_path = Path("benchmark/pipeline_c/candidate/report.json")
    
    if not optimized_path.exists():
        print(f"⚠ Optimized report not found at {optimized_path}")
        print(f"  Expected location after running: benchmark/pipeline_c/candidate/report.json")
        print(f"\n  To generate optimized report, run:")
        print(f"    python benchmark/gen_report.py --pipeline c")
        return 1
    
    optimized = load_report(optimized_path)
    if not optimized:
        return 1
    
    print(f"✓ Optimized report loaded")
    
    # Extract KPIs
    print("\n[STEP 3] Extracting metrics...")
    
    try:
        baseline_hash = baseline['kpi_3_output_validation']['output_hash']
        baseline_rows = baseline['kpi_3_output_validation']['row_count']
        baseline_runtime = baseline['kpi_1_execution']['runtime_seconds']
        
        optimized_hash = optimized['kpi_3_output_validation']['output_hash']
        optimized_rows = optimized['kpi_3_output_validation']['row_count']
        optimized_runtime = optimized['kpi_1_execution']['runtime_seconds']
    except KeyError as e:
        print(f"✗ Missing key in report: {e}")
        return 1
    
    expected_hash = "bdf3589bf1273b1ff3622c8ff4dcc7797cd25d17cec9bea7334c05d7dd157354"
    expected_rows = 53000
    
    # Print comparison
    print("\n" + "="*60)
    print("METRIC COMPARISON")
    print("="*60)
    
    print(f"\nData Integrity (Output Hash):")
    print(f"  Expected:   {expected_hash}")
    print(f"  Baseline:   {baseline_hash}")
    print(f"  Optimized:  {optimized_hash}")
    if optimized_hash == expected_hash:
        print(f"  ✓ PASS: Hash matches expected")
    else:
        print(f"  ✗ FAIL: Hash does NOT match expected")
    
    print(f"\nData Completeness (Row Count):")
    print(f"  Expected:   {expected_rows:,}")
    print(f"  Baseline:   {baseline_rows:,}")
    print(f"  Optimized:  {optimized_rows:,}")
    if optimized_rows == expected_rows:
        print(f"  ✓ PASS: Row count matches expected")
    else:
        print(f"  ✗ FAIL: Row count does NOT match expected")
    
    print(f"\nPerformance (Runtime in seconds):")
    print(f"  Baseline:   {baseline_runtime}s")
    print(f"  Optimized:  {optimized_runtime}s")
    print(f"  Target:     20.0-25.0s")
    
    if baseline_runtime > 0:
        improvement_pct = ((baseline_runtime - optimized_runtime) / baseline_runtime) * 100
    else:
        improvement_pct = 0
    
    print(f"  Improvement: {improvement_pct:.1f}%")
    
    if optimized_runtime < baseline_runtime:
        print(f"  ✓ PASS: Performance improved")
    else:
        print(f"  ⚠ NOTE: Performance did NOT improve")
    
    if 20.0 <= optimized_runtime <= 25.0:
        print(f"  ✓ EXCELLENT: Runtime in target range (20-25s)")
    elif optimized_runtime < baseline_runtime:
        print(f"  ~ ACCEPTABLE: Runtime improved but not in ideal target range")
    
    # Validation results
    print("\n" + "="*60)
    print("VALIDATION RESULTS")
    print("="*60)
    
    hash_pass = optimized_hash == expected_hash
    rows_pass = optimized_rows == expected_rows
    perf_pass = optimized_runtime < baseline_runtime
    
    print(f"\n[CHECK 1] Data Integrity (Hash):     {'✓ PASS' if hash_pass else '✗ FAIL'}")
    print(f"[CHECK 2] Data Completeness (Rows): {'✓ PASS' if rows_pass else '✗ FAIL'}")
    print(f"[CHECK 3] Performance Improvement:   {'✓ PASS' if perf_pass else '⚠ NO IMPROVEMENT'}")
    
    if hash_pass and rows_pass:
        print(f"\n{'='*60}")
        print(f"✓✓✓ SUCCESS: Data integrity validated")
        print(f"    Optimization logic is correct (data unchanged)")
        if perf_pass:
            print(f"✓✓✓ BONUS: Performance improved by {improvement_pct:.1f}%")
        print(f"{'='*60}")
        return 0
    else:
        print(f"\n{'='*60}")
        print(f"✗✗✗ FAILURE: Data integrity check failed")
        print(f"    Optimization logic may be incorrect or corrupted")
        if not hash_pass:
            print(f"    - Output hash mismatch")
        if not rows_pass:
            print(f"    - Row count mismatch")
        print(f"{'='*60}")
        return 1

if __name__ == '__main__':
    sys.exit(main())
