-- Pipeline C: Complex Portfolio Analytics
-- Model: report_lp_quarterly
-- Description: Quarterly LP reporting with period comparisons
--
-- ISSUES FOR ARTEMIS TO OPTIMIZE:
-- 1. Heavy date manipulation
-- 2. Multiple aggregation passes
-- 3. Complex period-over-period calculations
-- 4. Window functions that span large partitions

with portfolio_performance as (
    select * from BAIN_ANALYTICS.DEV.fact_portfolio_performance
),

cashflow_summary as (
    select * from BAIN_ANALYTICS.DEV.fact_cashflow_summary
),

-- ISSUE: Filter to quarter-end dates only
quarter_end_perf as (
    select *
    from portfolio_performance
    where valuation_date = last_day(valuation_date, 'quarter')
),

-- ISSUE: Aggregate cashflows to quarterly
quarterly_cashflows as (
    select
        portfolio_id,
        date_trunc('quarter', cashflow_month) as quarter_start,
        sum(case when cashflow_type = 'CONTRIBUTION' then total_amount else 0 end) as quarterly_contributions,
        sum(case when cashflow_type = 'DISTRIBUTION' then total_amount else 0 end) as quarterly_distributions,
        sum(total_amount) as quarterly_net_cashflow
    from cashflow_summary
    group by 1, 2
),

-- ISSUE: Join performance and cashflows
combined as (
    select
        qep.portfolio_id,
        qep.portfolio_name,
        qep.portfolio_type,
        qep.fund_id,
        qep.valuation_date as quarter_end,
        qep.valuation_quarter_start as quarter_start,
        qep.valuation_year,
        qep.valuation_quarter,
        qep.nav_usd,
        qep.portfolio_return_3m as quarterly_return,
        qep.portfolio_return_1y,
        qep.portfolio_cumulative_return,
        qep.benchmark_return_3m as benchmark_quarterly_return,
        qep.excess_return_3m as quarterly_excess_return,
        qep.sharpe_ratio,
        qep.max_drawdown,
        qcf.quarterly_contributions,
        qcf.quarterly_distributions,
        qcf.quarterly_net_cashflow
    from quarter_end_perf qep
    left join quarterly_cashflows qcf
        on qep.portfolio_id = qcf.portfolio_id
        and qep.valuation_quarter_start = qcf.quarter_start
),

-- ISSUE: Period comparisons with multiple LAGs
with_comparisons as (
    select
        *,
        -- Prior quarter
        lag(nav_usd, 1) over (partition by portfolio_id order by quarter_end) as prior_quarter_nav,
        lag(quarterly_return, 1) over (partition by portfolio_id order by quarter_end) as prior_quarter_return,
        -- Prior year same quarter
        lag(nav_usd, 4) over (partition by portfolio_id order by quarter_end) as prior_year_nav,
        lag(quarterly_return, 4) over (partition by portfolio_id order by quarter_end) as prior_year_quarterly_return,
        -- Running totals
        sum(quarterly_contributions) over (
            partition by portfolio_id
            order by quarter_end
            rows between unbounded preceding and current row
        ) as cumulative_contributions,
        sum(quarterly_distributions) over (
            partition by portfolio_id
            order by quarter_end
            rows between unbounded preceding and current row
        ) as cumulative_distributions
    from combined
),

-- ISSUE: Calculate growth and other metrics
final as (
    select
        portfolio_id,
        portfolio_name,
        portfolio_type,
        fund_id,
        quarter_end,
        quarter_start,
        valuation_year,
        valuation_quarter,
        concat('Q', valuation_quarter, ' ', valuation_year) as quarter_label,
        nav_usd,
        quarterly_return,
        benchmark_quarterly_return,
        quarterly_excess_return,
        portfolio_return_1y as trailing_1y_return,
        portfolio_cumulative_return as since_inception_return,
        sharpe_ratio,
        max_drawdown,
        quarterly_contributions,
        quarterly_distributions,
        quarterly_net_cashflow,
        cumulative_contributions,
        cumulative_distributions,
        -- QoQ changes
        case
            when prior_quarter_nav > 0
            then (nav_usd - prior_quarter_nav) / prior_quarter_nav * 100
            else null
        end as qoq_nav_growth_pct,
        quarterly_return - coalesce(prior_quarter_return, 0) as qoq_return_change,
        -- YoY changes
        case
            when prior_year_nav > 0
            then (nav_usd - prior_year_nav) / prior_year_nav * 100
            else null
        end as yoy_nav_growth_pct,
        quarterly_return - coalesce(prior_year_quarterly_return, 0) as yoy_return_change,
        -- TVPI and DPI
        case
            when cumulative_contributions > 0
            then (nav_usd + cumulative_distributions) / cumulative_contributions
            else null
        end as tvpi,
        case
            when cumulative_contributions > 0
            then cumulative_distributions / cumulative_contributions
            else null
        end as dpi
    from with_comparisons
)

select * from final
order by portfolio_id, quarter_end