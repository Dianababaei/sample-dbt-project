# Portfolio Analytics - Production dbt Project

Real-world production dbt project with 3 pipelines of increasing complexity.

## Project Structure

**Pipeline A (Simple):** 4 models
```
Staging: stg_portfolios, stg_cashflows
Intermediate: int_portfolio_attributes, int_cashflow_aggregated
```

**Pipeline B (Medium):** 12 models
```
Staging: stg_trades, stg_securities, stg_market_prices, stg_brokers
Intermediate: int_trades_enriched, int_trade_metrics, int_trade_summary, int_security_performance, int_trade_execution_analysis
Marts: fact_trades, report_trading_performance, report_trade_performance
```

**Pipeline C (Complex):** 26 models
```
Staging: stg_positions_daily, stg_valuations, stg_benchmarks, stg_benchmark_returns, stg_portfolio_benchmarks
Intermediate: int_position_enriched, int_position_returns, int_portfolio_returns, int_risk_metrics,
             int_sector_allocation, int_portfolio_analysis_advanced, int_position_risk_decomposition,
             int_sector_rotation_analysis, int_performance_attribution_detailed, int_portfolio_drawdown,
             int_rolling_volatility, int_position_attribution, int_sector_performance_attribution
Marts: fact_portfolio_performance, fact_position_snapshot, fact_sector_performance,
       report_executive_summary, report_performance_drivers, report_portfolio_risk_analysis,
       report_position_attribution, report_sector_analysis
```

## Characteristics

- **Linear Dependencies:** Clean staging → intermediate → marts → reports flow
- **Production-Ready:** Real-world patterns including intentional optimization opportunities
- **Portable Design:** Focus on maintainability over early optimization
- **Snowflake Target:** Optimized for Snowflake with window functions, CTEs, and advanced analytics

## Key Optimization Opportunities

These patterns demonstrate typical challenges companies face:
- Heavy joins at fact layer (can be pushed upstream)
- Redundant window function calculations
- Late aggregation (pre-aggregate in intermediate layer)
- Repeated calculations across pipelines

## Quick Start

```bash
dbt deps
dbt seed
dbt run
dbt test
```

## Running

```bash
# Build all pipelines
dbt run

# Build specific pipeline
dbt run --select tag:pipeline_a
dbt run --select tag:pipeline_b
dbt run --select tag:pipeline_c

# Build specific layer across all pipelines
dbt run --select tag:staging
dbt run --select tag:intermediate
dbt run --select tag:marts

# Run tests
dbt test

# Generate docs
dbt docs generate && dbt docs serve
```

## Benchmarking

The project includes benchmarking support for testing optimizations across 3 pipelines. Each benchmark captures 5 KPIs:

1. **KPI 1:** Execution time (seconds)
2. **KPI 2:** Work metrics (rows returned, bytes scanned)
3. **KPI 3:** Output validation (SHA256 hash for equivalence checking)
4. **KPI 4:** Query complexity (JOINs, CTEs, window functions)
5. **KPI 5:** Cost estimation (Snowflake credits)

### Benchmark Workflow

```bash
# 1. Single pipeline benchmark (compiles, runs, and generates report)
cd benchmark
python gen_report_b.py              # Run Pipeline B
python gen_report_a.py              # Run Pipeline A
python gen_report_c.py              # Run Pipeline C

# Or run all pipelines at once:
python run_all_benchmarks.py

# 2. View results
cat pipeline_b/candidate/report.json

# 3. Apply optimizations to models
# (Edit models in models/pipeline_*/intermediate or models/pipeline_*/marts)

# 4. Re-run benchmark to measure improvements
python gen_report_b.py

# 5. Compare metrics with previous run
cat pipeline_b/candidate/report.json
```

### Benchmark Directory Structure

```
benchmark/
├── gen_report_a.py             # Pipeline A benchmark script
├── gen_report_b.py             # Pipeline B benchmark script
├── gen_report_c.py             # Pipeline C benchmark script
├── run_all_benchmarks.py       # Master script (runs all 3)
├── compare_kpis.py             # KPI comparison tool
├── README.md                   # Benchmarking documentation
├── QUICK_START.md              # Quick reference guide
├── pipeline_a/
│   ├── baseline/report.json    # Baseline metrics
│   └── candidate/report.json   # Latest run results
├── pipeline_b/
│   ├── baseline/report.json
│   └── candidate/report.json
└── pipeline_c/
    ├── baseline/report.json
    └── candidate/report.json
```

## Total Models

- **Staging:** 11 models (stg_*)
  - Pipeline A: 2 | Pipeline B: 4 | Pipeline C: 5
- **Intermediate:** 20 models (int_*)
  - Pipeline A: 2 | Pipeline B: 5 | Pipeline C: 13
- **Marts:** 11 models (fact_*, report_*)
  - Pipeline A: 0 | Pipeline B: 3 | Pipeline C: 8

**Total:** 42 models across 3 pipelines
