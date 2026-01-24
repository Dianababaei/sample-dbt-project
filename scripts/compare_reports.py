#!/usr/bin/env python3
"""
Report Comparison Script

Validates that baseline and optimized reports are identical.
This ensures Artemis optimization doesn't change financial outputs.

Usage:
    python compare_reports.py <baseline.csv> <optimized.csv> [output.json]

Examples:
    python compare_reports.py output/baseline_report.csv output/optimised_report.csv
    python compare_reports.py output/baseline_report.csv output/optimised_report.csv output/comparison_result.json
"""

import pandas as pd
import json
import sys
from pathlib import Path
from typing import Tuple, Dict, Any


def load_report(filepath: str) -> pd.DataFrame:
    """Load CSV report with proper handling of data types."""
    try:
        df = pd.read_csv(filepath)
        print(f"✅ Loaded: {filepath} ({len(df)} rows, {len(df.columns)} columns)")
        return df
    except FileNotFoundError:
        print(f"❌ Error: File not found - {filepath}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error loading file: {e}")
        sys.exit(1)


def compare_shape(baseline: pd.DataFrame, optimized: pd.DataFrame) -> Dict[str, Any]:
    """Compare DataFrame shapes."""
    baseline_shape = baseline.shape
    optimized_shape = optimized.shape
    match = baseline_shape == optimized_shape

    result = {
        "baseline_shape": baseline_shape,
        "optimized_shape": optimized_shape,
        "match": match,
    }

    if match:
        print(f"✅ Shape: {baseline_shape} (identical)")
    else:
        print(f"❌ Shape mismatch:")
        print(f"   Baseline:  {baseline_shape}")
        print(f"   Optimized: {optimized_shape}")

    return result


def compare_columns(baseline: pd.DataFrame, optimized: pd.DataFrame) -> Dict[str, Any]:
    """Compare column names and order."""
    baseline_cols = list(baseline.columns)
    optimized_cols = list(optimized.columns)
    match = baseline_cols == optimized_cols

    result = {
        "baseline_columns": baseline_cols,
        "optimized_columns": optimized_cols,
        "match": match,
    }

    if match:
        print(f"✅ Columns: {len(baseline_cols)} columns (identical)")
    else:
        print(f"❌ Column mismatch:")
        baseline_set = set(baseline_cols)
        optimized_set = set(optimized_cols)
        missing = baseline_set - optimized_set
        added = optimized_set - baseline_set
        if missing:
            print(f"   Missing in optimized: {missing}")
        if added:
            print(f"   Added in optimized: {added}")
        if baseline_cols != optimized_cols:
            print(f"   Baseline:  {baseline_cols}")
            print(f"   Optimized: {optimized_cols}")

    return result


def compare_values(baseline: pd.DataFrame, optimized: pd.DataFrame) -> Dict[str, Any]:
    """Compare actual data values."""
    # Check for exact equality first
    if baseline.equals(optimized):
        print("✅ Values: All values identical (bit-for-bit)")
        return {
            "match": True,
            "identical_rows": len(baseline),
            "different_rows": 0,
            "differences": [],
        }

    # Find differences row-by-row
    differences = []
    for idx in range(len(baseline)):
        for col in baseline.columns:
            baseline_val = baseline.iloc[idx][col]
            optimized_val = optimized.iloc[idx][col]

            # Compare with tolerance for floats
            try:
                if isinstance(baseline_val, float) and isinstance(optimized_val, float):
                    if abs(baseline_val - optimized_val) > 1e-10:
                        differences.append({
                            "row": idx,
                            "column": col,
                            "baseline": baseline_val,
                            "optimized": optimized_val,
                            "difference": optimized_val - baseline_val,
                        })
                elif baseline_val != optimized_val:
                    differences.append({
                        "row": idx,
                        "column": col,
                        "baseline": str(baseline_val),
                        "optimized": str(optimized_val),
                    })
            except Exception:
                differences.append({
                    "row": idx,
                    "column": col,
                    "baseline": str(baseline_val),
                    "optimized": str(optimized_val),
                    "error": "Comparison failed",
                })

    if differences:
        print(f"❌ Values: {len(differences)} differences found")
        print(f"   First 5 differences:")
        for diff in differences[:5]:
            print(f"   Row {diff['row']}, Col '{diff['column']}':")
            print(f"      Baseline:  {diff['baseline']}")
            print(f"      Optimized: {diff['optimized']}")
        if len(differences) > 5:
            print(f"   ... and {len(differences) - 5} more")

        return {
            "match": False,
            "identical_rows": len(baseline) - len(set(d["row"] for d in differences)),
            "different_rows": len(set(d["row"] for d in differences)),
            "total_differences": len(differences),
            "first_differences": differences[:10],
        }
    else:
        print("✅ Values: All values identical (within tolerance)")
        return {
            "match": True,
            "identical_rows": len(baseline),
            "different_rows": 0,
            "differences": [],
        }


def compute_financial_metrics(df: pd.DataFrame) -> Dict[str, Any]:
    """Compute aggregate financial metrics."""
    metrics = {
        "row_count": len(df),
        "numeric_columns": len(df.select_dtypes(include=['number']).columns),
    }

    # Sum all numeric columns
    numeric_df = df.select_dtypes(include=['number'])
    if not numeric_df.empty:
        metrics["total_sum"] = float(numeric_df.sum().sum())
        metrics["total_mean"] = float(numeric_df.mean().mean())
        metrics["total_std"] = float(numeric_df.std().mean())

        # Also per-column for key metrics
        for col in numeric_df.columns:
            metrics[f"{col}_sum"] = float(numeric_df[col].sum())
            metrics[f"{col}_count"] = int(numeric_df[col].count())

    return metrics


def compare_reports(
    baseline_path: str,
    optimized_path: str,
    output_json: str = None
) -> Tuple[bool, Dict[str, Any]]:
    """
    Main comparison function.

    Returns:
        Tuple of (success: bool, results: dict)
    """
    print("\n" + "=" * 70)
    print("📊 REPORT COMPARISON - Artemis Demo Validation")
    print("=" * 70)
    print()

    # Load reports
    print("📂 Loading reports...")
    baseline = load_report(baseline_path)
    optimized = load_report(optimized_path)
    print()

    # Run comparisons
    print("🔍 Running comparisons...")
    print()

    shape_result = compare_shape(baseline, optimized)
    print()

    column_result = compare_columns(baseline, optimized)
    print()

    value_result = compare_values(baseline, optimized)
    print()

    # Compute metrics
    print("📈 Computing financial metrics...")
    baseline_metrics = compute_financial_metrics(baseline)
    optimized_metrics = compute_financial_metrics(optimized)
    print()

    # Overall result
    overall_success = (
        shape_result["match"]
        and column_result["match"]
        and value_result["match"]
    )

    # Compile results
    results = {
        "status": "PASS" if overall_success else "FAIL",
        "summary": {
            "overall_match": overall_success,
            "shape_match": shape_result["match"],
            "columns_match": column_result["match"],
            "values_match": value_result["match"],
        },
        "shape": shape_result,
        "columns": column_result,
        "values": value_result,
        "baseline_metrics": baseline_metrics,
        "optimized_metrics": optimized_metrics,
    }

    # Print summary
    print("=" * 70)
    if overall_success:
        print("✅ SUCCESS: Reports are identical!")
        print("Artemis optimization is validated - outputs unchanged.")
    else:
        print("❌ FAILURE: Reports differ!")
        print("Artemis changes affected financial outputs (not allowed).")
    print("=" * 70)
    print()

    # Save results if requested
    if output_json:
        with open(output_json, 'w') as f:
            # Convert any non-JSON-serializable types
            json.dump(results, f, indent=2, default=str)
        print(f"📄 Results saved to: {output_json}")
        print()

    return overall_success, results


def main():
    """CLI entry point."""
    if len(sys.argv) < 3:
        print("Usage: python compare_reports.py <baseline.csv> <optimized.csv> [output.json]")
        print()
        print("Examples:")
        print("  python compare_reports.py baseline_report.csv optimised_report.csv")
        print("  python compare_reports.py baseline.csv optimised.csv comparison_result.json")
        sys.exit(1)

    baseline_path = sys.argv[1]
    optimized_path = sys.argv[2]
    output_json = sys.argv[3] if len(sys.argv) > 3 else None

    success, results = compare_reports(baseline_path, optimized_path, output_json)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
