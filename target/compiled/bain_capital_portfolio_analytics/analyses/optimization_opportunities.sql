/*
================================================================================
ARTEMIS OPTIMIZATION OPPORTUNITIES ANALYSIS
================================================================================

This file documents the optimization opportunities that Artemis should identify
and fix when processing this dbt project.

================================================================================
PIPELINE A: SIMPLE CASHFLOW PIPELINE (4 models)
================================================================================

Model: stg_cashflows
----------------------
Issues:
1. Unnecessary DISTINCT on source (source already unique by PK)
2. Filter applied AFTER transformations (should filter first)
3. Type casting could be pushed to source definition

Suggested Optimization:
- Remove DISTINCT
- Move WHERE clause to first CTE
- Use QUALIFY if deduplication needed

Model: stg_portfolios
----------------------
Issues:
1. Deduplication uses subquery + WHERE instead of QUALIFY
2. Multiple CTEs for simple operations

Suggested Optimization:
- Use QUALIFY row_number() over (...) = 1
- Combine CTEs

Model: fact_cashflow_summary
-----------------------------
Issues:
1. Full row-level join before aggregation (scans all rows)
2. Date dimensions calculated per row
3. Non-descriptive GROUP BY (uses column numbers)

Suggested Optimization:
- Aggregate cashflows FIRST, then join to portfolios
- Calculate date dimensions once
- Use explicit column names in GROUP BY

Model: report_monthly_cashflows
--------------------------------
Issues:
1. Re-aggregates already aggregated fact data
2. Multiple identical window function partitions
3. LAG functions calculated separately

Suggested Optimization:
- Reference pre-aggregated data where possible
- Consolidate window functions with same PARTITION BY/ORDER BY
- Use single window clause with multiple functions

================================================================================
PIPELINE B: TRADE ANALYTICS PIPELINE (10 models)
================================================================================

Model: stg_trades
------------------
Issues:
1. Repeated CASE statements for categorization (duplicated in other models)
2. Multiple CTEs for sequential transformations
3. Late filtering (filter applied after all transformations)

Suggested Optimization:
- Extract trade categorization to macro
- Combine transformations
- Filter in first CTE

Model: stg_securities
----------------------
Issues:
1. Nested subquery for deduplication
2. Repeated CASE for type standardization (similar to other models)

Suggested Optimization:
- Use QUALIFY
- Create macro for security type standardization

Model: stg_market_prices
-------------------------
Issues:
1. SELF-JOIN for prior day prices (very expensive)
2. Multiple window functions with same partition
3. Additional CTE for derived calculations

Suggested Optimization:
- Use LAG() instead of self-join
- Consolidate window functions
- Combine CTEs

Model: int_trades_enriched
---------------------------
Issues:
1. 4-way join (trades + securities + brokers + market_prices)
2. Price lookup done row-by-row
3. Calculations done per trade row

Suggested Optimization:
- Pre-aggregate market prices if possible
- Consider materialization strategy
- Push some calculations upstream

Model: int_trade_pnl
---------------------
Issues:
1. Multiple window functions with identical PARTITION BY/ORDER BY
2. Separate CTEs for each calculation layer
3. Complex running position logic

Suggested Optimization:
- Consolidate window functions into single SELECT
- Use Snowflake's multi-column window functions
- Simplify CTE structure

Model: fact_trade_summary
--------------------------
Issues:
1. Re-joins portfolio data (already available upstream)
2. Redundant date extractions (already done in staging)
3. Surrogate key generation overhead

Suggested Optimization:
- Pass portfolio attributes through from upstream
- Reuse date dimensions from staging
- Consider if surrogate key is necessary

Model: fact_portfolio_positions
--------------------------------
Issues:
1. Double subquery pattern for "latest" records
2. Market prices joined inefficiently

Suggested Optimization:
- Use QUALIFY for latest positions
- Pre-compute latest market prices in separate CTE
- Consider incremental materialization

Model: report_trading_performance
----------------------------------
Issues:
1. Re-aggregates fact data by portfolio/month
2. Joins positions and trades separately
3. Multiple LAG functions

Suggested Optimization:
- Create intermediate aggregation layer
- Join once with all needed dimensions
- Consolidate window calculations

================================================================================
PIPELINE C: COMPLEX PORTFOLIO ANALYTICS (20 models)
================================================================================

General DAG-Level Issues:
-------------------------
1. Position attribution calculated per-day, then re-aggregated to sector
2. Risk metrics and performance metrics calculated in parallel but not shared
3. Benchmark alignment done for each portfolio-date combination (expensive)
4. Fund roll-up happens late, after all portfolio calculations
5. Report models re-aggregate fact tables

Model: int_portfolio_returns_daily
-----------------------------------
Issues:
1. Self-join for prior day NAV (should use LAG)
2. 7 separate window functions for rolling returns
3. 2 additional window functions for volatility
4. All use same PARTITION BY/ORDER BY

Suggested Optimization:
- Use LAG() for prior NAV
- Create single window definition
- Compute all rolling metrics in one pass

Model: int_benchmark_aligned
-----------------------------
Issues:
1. Cross-join-like pattern (portfolio dates × benchmarks)
2. Could pre-filter to active benchmarks only

Suggested Optimization:
- Filter benchmarks before join
- Consider materialization strategy
- Index on benchmark_id + date

Model: int_portfolio_vs_benchmark
----------------------------------
Issues:
1. Joins data already joined in upstream models
2. Excess return calculated multiple times
3. Rolling tracking error requires another window pass

Suggested Optimization:
- Pass benchmark data through from earlier
- Calculate excess returns once
- Combine tracking error with other window calcs

Model: int_position_attribution
--------------------------------
Issues:
1. 3-way join (positions + securities + prices)
2. Window functions for prior weight
3. Attribution calculated per position

Suggested Optimization:
- Consider different join order
- Pre-aggregate where possible
- Brinson attribution could be modularized

Model: int_sector_attribution
------------------------------
Issues:
1. Re-aggregates position attribution
2. Multiple window functions for rolling
3. Separate calculation from position level

Suggested Optimization:
- Consider pushing sector aggregation upstream
- Combine with position attribution model
- Reduce number of CTEs

Model: int_risk_metrics
------------------------
Issues:
1. Multiple window functions for risk calcs
2. VaR calculated after other metrics (extra pass)
3. Max drawdown requires running max

Suggested Optimization:
- Consolidate risk calculations
- Compute VaR alongside volatility
- Single window definition for all

Model: int_fund_rollup
-----------------------
Issues:
1. Gets latest metrics via subquery (should use QUALIFY)
2. Aggregates after joining
3. Weighted average calculations

Suggested Optimization:
- Use QUALIFY for latest
- Aggregate first, then join hierarchy
- Simplify weighted calcs

Model: fact_portfolio_performance
----------------------------------
Issues:
1. Joins benchmark and risk data that share same key
2. Portfolio attributes added at end
3. Date extractions repeated

Suggested Optimization:
- Single join for all metrics
- Push portfolio join upstream
- Calculate dates once in staging

Model: report_ic_dashboard
---------------------------
Issues:
1. Gets "latest" via subquery (3 times!)
2. Re-aggregates positions for summary
3. Sector concentration via nested query
4. Multiple ranking functions

Suggested Optimization:
- Use QUALIFY for latest records
- Create intermediate "latest portfolio state" model
- Pre-compute sector concentrations
- Combine rankings

Model: report_lp_quarterly
---------------------------
Issues:
1. Filters to quarter-end only (late in pipeline)
2. Re-aggregates cashflows
3. Multiple LAG functions for period comparisons
4. TVPI/DPI calculated at end

Suggested Optimization:
- Filter earlier in pipeline
- Pre-aggregate cashflows quarterly
- Consolidate LAG calculations
- Calculate investment metrics upstream

================================================================================
SNOWFLAKE-SPECIFIC OPTIMIZATIONS
================================================================================

1. QUALIFY Usage
   - Every row_number() + WHERE rn=1 pattern should become QUALIFY
   - Estimated models affected: 12

2. Window Function Consolidation
   - Models with 5+ window functions using same partition: 8
   - Potential reduction: 40-60% of window function overhead

3. Join Order Optimization
   - Several multi-way joins could benefit from different join order
   - Snowflake's join optimization works best with explicit hints

4. Materialization Strategy
   - Intermediate models: Consider TABLE instead of VIEW for heavy calcs
   - Staging models: VIEW is appropriate
   - Consider incremental for daily position/valuation models

5. Clustering Keys
   - fact_portfolio_performance: CLUSTER BY (portfolio_id, valuation_date)
   - fact_position_snapshot: CLUSTER BY (portfolio_id, position_date)
   - fact_trade_summary: CLUSTER BY (portfolio_id, trade_date)

================================================================================
CROSS-MODEL OPTIMIZATIONS
================================================================================

1. Shared Calculations
   - Date dimensions calculated in 15+ places → extract to dim_date
   - Trade categorization logic duplicated → extract to macro
   - Deduplication pattern repeated → use QUALIFY consistently

2. Pre-Aggregation Opportunities
   - Daily position data → pre-aggregate to weekly/monthly
   - Trade data → pre-aggregate to portfolio/security/period

3. Intermediate Layer Restructure
   - int_portfolio_returns_daily could include benchmark data
   - int_position_attribution could include sector aggregation
   - Single "portfolio state" model for latest data

4. DAG Simplification
   - Pipeline C has 7 intermediate models that could be reduced to 4
   - Some fact tables could be combined

================================================================================
EXPECTED IMPROVEMENTS
================================================================================

Conservative Estimates:
- dbt run time: 30-50% reduction
- Snowflake credits: 25-40% reduction
- Query complexity: 40% fewer CTEs
- Warehouse scan volume: 35% reduction

Financial Accuracy Validation:
- Row counts must match pre/post optimization
- Sum(NAV), Sum(PnL), Sum(cashflows) must match within tolerance
- All dbt tests must pass
- No silent drift in portfolio metrics

================================================================================
*/