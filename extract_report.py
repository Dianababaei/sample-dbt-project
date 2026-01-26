#!/usr/bin/env python3
"""Extract report from FACT_CASHFLOW_SUMMARY for benchmarking

KPIs captured:
1. Execution time (runtime_seconds)
2. Work performed (bytes_scanned, rows_processed)
3. Output validation (row_count, output_hash)
4. Query complexity (num_joins, ctes, window_functions)
"""

import json
import os
import sys
import hashlib
from datetime import datetime
import time

def calculate_output_hash(data):
    """Calculate SHA256 hash of output data for validation"""
    data_str = json.dumps(data, sort_keys=True, default=str)
    return hashlib.sha256(data_str.encode()).hexdigest()

def main():
    output_dir = "benchmark/candidate"
    os.makedirs(output_dir, exist_ok=True)

    try:
        from snowflake.connector import connect

        account = os.getenv('SNOWFLAKE_ACCOUNT')
        user = os.getenv('SNOWFLAKE_USER')
        password = os.getenv('SNOWFLAKE_PASSWORD')

        if not all([account, user, password]):
            raise ValueError("Missing Snowflake credentials")

        # Connect to Snowflake
        query_start = time.time()
        conn = connect(
            account=account,
            user=user,
            password=password,
            warehouse='COMPUTE_WH',
            database='BAIN_ANALYTICS',
            schema='DEV'
        )

        # Execute main query
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM FACT_CASHFLOW_SUMMARY ORDER BY portfolio_id, cashflow_month, cashflow_type")

        columns = [desc[0] for desc in cursor.description]
        rows = cursor.fetchall()

        query_time = time.time() - query_start

        cursor.close()
        conn.close()

        # Convert to dictionaries
        data = [dict(zip(columns, row)) for row in rows]

        # Calculate output hash for validation
        output_hash = calculate_output_hash(data)

        # Create report with 4 KPIs for benchmarking
        metadata = {
            'timestamp': datetime.now().isoformat(),
            'pipeline': 'dbt sample project',
            'target_table': 'FACT_CASHFLOW_SUMMARY',

            # KPI 1: Execution Time (deterministic, immediate)
            'kpi_1_execution': {
                'runtime_seconds': round(query_time, 4),
                'description': 'End-to-end query execution time'
            },

            # KPI 2: Work Performed (cost proxy - deterministic)
            'kpi_2_work_metrics': {
                'rows_returned': len(data),
                'description': 'Rows in final output (correlates with Snowflake cost)'
            },

            # KPI 3: Output Validation (deterministic)
            'kpi_3_output_validation': {
                'row_count': len(data),
                'output_hash': output_hash,
                'description': 'SHA256 hash for output equivalence checking'
            },

            # KPI 4: Query Complexity (qualitative)
            'kpi_4_complexity': {
                'description': 'Query structure complexity (check dbt graph)'
            }
        }

        report = {
            'metadata': metadata,
            'data': data
        }

        # Save report
        output_file = os.path.join(output_dir, 'report.json')
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2, default=str)

        runtime = report['metadata']['kpi_1_execution']['runtime_seconds']
        rows = report['metadata']['kpi_3_output_validation']['row_count']
        hash_short = report['metadata']['kpi_3_output_validation']['output_hash'][:8]

        print(f"[OK] Report generated:")
        print(f"     - Rows: {rows}")
        print(f"     - Runtime: {runtime}s")
        print(f"     - Output Hash: {hash_short}...")
        return 0

    except ImportError:
        print("[ERROR] snowflake-connector-python not installed")
        return 1

    except Exception as e:
        print(f"[ERROR] {e}")
        return 1

if __name__ == '__main__':
    sys.exit(main())
