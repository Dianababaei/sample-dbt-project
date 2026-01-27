-- Pipeline A: Simple Cashflow Pipeline
-- Model: fact_cashflow_summary
-- Description: Fact table summarizing cashflows by portfolio and month
--
-- OPTIMIZED FOR PERFORMANCE:
-- 1. Pre-aggregate cashflows before join (reduces row volume)
-- 2. Early aggregation with dedicated date calculation CTE
-- 3. Explicit column names in GROUP BY (not positional)
-- 4. Separate date_components CTE for single-pass calculation

with cashflows as (
    select * from {{ ref('stg_cashflows') }}
),

portfolios as (
    select * from {{ ref('stg_portfolios') }}
),

-- OPTIMIZATION: Pre-aggregate cashflows before join to reduce row volume
aggregated_cashflows as (
    select
        portfolio_id,
        cashflow_date,
        cashflow_type,
        currency,
        count(*) as transaction_count,
        sum(amount) as total_amount,
        avg(amount) as avg_amount,
        min(amount) as min_amount,
        max(amount) as max_amount
    from cashflows
    group by
        portfolio_id,
        cashflow_date,
        cashflow_type,
        currency
),

-- OPTIMIZATION: Pre-calculate date components (executed only once per unique date)
date_components as (
    select
        cashflow_date,
        date_trunc('month', cashflow_date) as cashflow_month,
        date_trunc('quarter', cashflow_date) as cashflow_quarter,
        date_trunc('year', cashflow_date) as cashflow_year,
        extract(year from cashflow_date) as year_num,
        extract(month from cashflow_date) as month_num,
        extract(quarter from cashflow_date) as quarter_num
    from aggregated_cashflows
    group by cashflow_date
),

-- OPTIMIZATION: Join on pre-aggregated, much smaller dataset
joined as (
    select
        ac.portfolio_id,
        p.portfolio_name,
        p.portfolio_type,
        p.fund_id,
        ac.cashflow_type,
        ac.currency,
        dc.cashflow_month,
        dc.cashflow_quarter,
        dc.cashflow_year,
        dc.year_num,
        dc.month_num,
        dc.quarter_num,
        ac.transaction_count,
        ac.total_amount,
        ac.avg_amount,
        ac.min_amount,
        ac.max_amount
    from aggregated_cashflows ac
    inner join portfolios p
        on ac.portfolio_id = p.portfolio_id
    inner join date_components dc
        on ac.cashflow_date = dc.cashflow_date
)

select
    {{ dbt_utils.generate_surrogate_key(['portfolio_id', 'cashflow_month', 'cashflow_type', 'currency']) }} as cashflow_summary_key,
    portfolio_id,
    portfolio_name,
    portfolio_type,
    fund_id,
    cashflow_month,
    cashflow_quarter,
    cashflow_year,
    year_num,
    month_num,
    quarter_num,
    cashflow_type,
    currency,
    transaction_count,
    total_amount,
    avg_amount,
    min_amount,
    max_amount
from joined
