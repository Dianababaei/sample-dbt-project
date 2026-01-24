
  
    

create or replace transient table BAIN_ANALYTICS.DEV.fact_cashflow_summary
    
    
    
    as (-- Pipeline A: Simple Cashflow Pipeline
-- Model: fact_cashflow_summary
-- Description: Fact table summarizing cashflows by portfolio and month
--
-- ISSUES FOR ARTEMIS TO OPTIMIZE:
-- 1. Heavy join repeated from other facts
-- 2. Late aggregation (aggregates after full join)
-- 3. Redundant date calculations
-- 4. Non-optimal GROUP BY

with cashflows as (
    select * from BAIN_ANALYTICS.DEV.stg_cashflows
),

portfolios as (
    select * from BAIN_ANALYTICS.DEV.stg_portfolios
),

-- ISSUE: Full join before aggregation (scans all rows)
joined as (
    select
        c.cashflow_id,
        c.portfolio_id,
        p.portfolio_name,
        p.portfolio_type,
        p.fund_id,
        c.cashflow_type,
        c.cashflow_date,
        c.amount,
        c.currency,
        -- ISSUE: Redundant date calculations done per row
        date_trunc('month', c.cashflow_date) as cashflow_month,
        date_trunc('quarter', c.cashflow_date) as cashflow_quarter,
        date_trunc('year', c.cashflow_date) as cashflow_year,
        extract(year from c.cashflow_date) as year_num,
        extract(month from c.cashflow_date) as month_num,
        extract(quarter from c.cashflow_date) as quarter_num
    from cashflows c
    inner join portfolios p
        on c.portfolio_id = p.portfolio_id
),

-- ISSUE: Aggregation happens after full row-level join
aggregated as (
    select
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
        count(*) as transaction_count,
        sum(amount) as total_amount,
        avg(amount) as avg_amount,
        min(amount) as min_amount,
        max(amount) as max_amount
    from joined
    group by 1,2,3,4,5,6,7,8,9,10,11,12  -- ISSUE: Non-descriptive GROUP BY
)

select
    md5(cast(coalesce(cast(portfolio_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cashflow_month as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cashflow_type as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(currency as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as cashflow_summary_key,
    *
from aggregated
    )
;


  