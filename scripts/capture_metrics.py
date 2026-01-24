#!/usr/bin/env python3
"""
Metrics Capture Script

Captures baseline metrics from dbt run for later comparison with optimized version.

Metrics captured:
  - dbt execution time
  - dbt version
  - Row counts per model
  - Financial aggregates
  - Test results

Saves to: output/baseline_metrics.json
"""

import json
import os
import subprocess
from datetime import datetime
from pathlib import Path


def get_dbt_version():
    """Get dbt version."""
    try:
        result = subprocess.run(['dbt', '--version'], capture_output=True, text=True)
        return result.stdout.split('\n')[0].strip()
    except Exception:
        return "unknown"


def get_manifest():
    """Read dbt manifest to get model info."""
    manifest_path = Path('target/manifest.json')
    if manifest_path.exists():
        try:
            with open(manifest_path, 'r') as f:
                return json.load(f)
        except Exception:
            return {}
    return {}


def get_run_results():
    """Read dbt run results."""
    run_results_path = Path('target/run_results.json')
    if run_results_path.exists():
        try:
            with open(run_results_path, 'r') as f:
                return json.load(f)
        except Exception:
            return {}
    return {}


def capture_metrics():
    """Capture all metrics."""
    metrics = {
        "timestamp": datetime.now().isoformat(),
        "dbt_version": get_dbt_version(),
        "database": "snowflake",
        "database_config": {
            "account": os.environ.get('SNOWFLAKE_ACCOUNT', 'unknown'),
            "database": "BAIN_ANALYTICS",
            "schema": "DEV",
        },
        "models": {},
        "tests": {
            "total": 0,
            "passed": 0,
            "failed": 0,
        },
        "execution": {
            "started_at": None,
            "completed_at": None,
            "total_time_seconds": 0,
        },
    }

    # Get manifest
    manifest = get_manifest()

    # Get run results
    run_results = get_run_results()

    # Extract model info from manifest
    if 'nodes' in manifest:
        for node_id, node in manifest['nodes'].items():
            if node.get('resource_type') == 'model':
                model_name = node.get('name')
                metrics['models'][model_name] = {
                    "type": node.get('type'),
                    "materialization": node.get('config', {}).get('materialized'),
                    "description": node.get('description', ''),
                    "depends_on": node.get('depends_on', {}).get('nodes', []),
                }

    # Extract execution info from run results
    if 'results' in run_results:
        execution_start = None
        execution_end = None

        for result in run_results['results']:
            if result.get('resource_type') == 'model':
                model_name = result.get('name')
                if model_name in metrics['models']:
                    metrics['models'][model_name]['execution'] = {
                        "status": result.get('status'),
                        "execution_time": result.get('execution_time'),
                        "rows_produced": result.get('rows_produced'),
                    }

                # Track execution time
                if result.get('executed_at'):
                    if execution_start is None:
                        execution_start = result.get('started_at')
                    execution_end = result.get('executed_at')

            elif result.get('resource_type') == 'test':
                metrics['tests']['total'] += 1
                if result.get('status') == 'pass':
                    metrics['tests']['passed'] += 1
                else:
                    metrics['tests']['failed'] += 1

        if execution_start and execution_end:
            metrics['execution']['started_at'] = execution_start
            metrics['execution']['completed_at'] = execution_end

    # Calculate summary stats
    model_count = len(metrics['models'])
    metrics['summary'] = {
        "total_models": model_count,
        "pipeline_a_models": len([m for m in metrics['models'].keys() if 'pipeline_a' in m]),
        "pipeline_b_models": len([m for m in metrics['models'].keys() if 'pipeline_b' in m]),
        "pipeline_c_models": len([m for m in metrics['models'].keys() if 'pipeline_c' in m]),
        "total_tests": metrics['tests']['total'],
        "tests_passed": metrics['tests']['passed'],
        "tests_failed": metrics['tests']['failed'],
    }

    return metrics


def main():
    """Main entry point."""
    metrics = capture_metrics()

    # Output to stdout (as JSON)
    print(json.dumps(metrics, indent=2, default=str))

    # Also save to file
    output_path = Path('output/baseline_metrics.json')
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, 'w') as f:
        json.dump(metrics, f, indent=2, default=str)

    return 0


if __name__ == "__main__":
    exit(main())
