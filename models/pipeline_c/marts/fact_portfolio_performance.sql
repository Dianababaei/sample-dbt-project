-- Pipeline C: Complex Portfolio Analytics
-- Model: fact_portfolio_performance
-- Description: Main performance fact table
--
-- ISSUES FOR ARTEMIS TO OPTIMIZE:
-- 1. Joins data already joined in intermediates
-- 2. Repeated calculations
-- 3. Large final select

with portfolio_vs_benchmark as (
    select * from {{ ref('int_portfolio_vs_benchmark') }}
),

risk_metrics as (
    select * from {{ ref('int_risk_metrics') }}
),

portfolios as (
    select * from {{ ref('stg_portfolios') }}
),

-- ISSUE: Another join when data could flow from upstream
combined as (
    select
        pvb.portfolio_id,
        pvb.valuation_date,
        pvb.nav,
        pvb.nav_usd,
        -- Portfolio returns
        pvb.portfolio_daily_return,
        pvb.portfolio_cumulative_return,
        pvb.portfolio_return_1m,
        pvb.portfolio_return_3m,
        pvb.portfolio_return_1y,
        pvb.portfolio_volatility,
        -- Benchmark comparison
        pvb.benchmark_id,
        pvb.benchmark_daily_return,
        pvb.benchmark_cumulative_return,
        pvb.benchmark_return_1m,
        pvb.benchmark_return_3m,
        pvb.benchmark_return_1y,
        pvb.benchmark_volatility,
        -- Relative performance
        pvb.daily_excess_return,
        pvb.cumulative_excess_return,
        pvb.excess_return_1m,
        pvb.excess_return_3m,
        pvb.excess_return_1y,
        pvb.tracking_error_1y,
        pvb.annualized_alpha,
        pvb.information_ratio,
        -- Risk metrics
        rm.drawdown,
        rm.max_drawdown,
        rm.downside_deviation_1y,
        rm.sharpe_ratio,
        rm.sortino_ratio,
        rm.var_95_1d,
        rm.var_99_1d
    from portfolio_vs_benchmark pvb
    inner join risk_metrics rm
        on pvb.portfolio_id = rm.portfolio_id
        and pvb.valuation_date = rm.valuation_date
),

-- ISSUE: Portfolio attributes added last
final as (
    select
        {{ dbt_utils.generate_surrogate_key(['c.portfolio_id', 'c.valuation_date']) }} as performance_key,
        p.portfolio_name,
        p.portfolio_type,
        p.fund_id,
        c.*,
        -- ISSUE: Date dimensions recalculated
        extract(year from c.valuation_date) as valuation_year,
        extract(month from c.valuation_date) as valuation_month,
        extract(quarter from c.valuation_date) as valuation_quarter,
        date_trunc('month', c.valuation_date) as valuation_month_start,
        date_trunc('quarter', c.valuation_date) as valuation_quarter_start
    from combined c
    inner join portfolios p
        on c.portfolio_id = p.portfolio_id
)

select * from final
