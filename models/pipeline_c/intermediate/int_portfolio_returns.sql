-- Pipeline C: Intermediate Layer
-- int_portfolio_returns.sql

{{ config(
    materialized='view',
    tags=['intermediate', 'pipeline_c'],
    meta={'pipeline': 'c', 'layer': 'intermediate'}
) }}

with valuations as (
    select * from {{ ref('stg_valuations') }}
),

lagged_values as (
    select
        *,
        lag(nav_usd) over (partition by portfolio_id order by valuation_date) as prev_nav_usd
    from valuations
),

returns as (
    select
        portfolio_id,
        valuation_date,
        nav,
        nav_usd,
        prev_nav_usd as prev_nav,
        nav_usd - prev_nav_usd as daily_pnl,
        case
            when prev_nav_usd > 0
            then (nav_usd - prev_nav_usd) / prev_nav_usd
            else 0
        end as daily_return_pct,
        extract(year from valuation_date) as valuation_year,
        extract(month from valuation_date) as valuation_month,
        extract(quarter from valuation_date) as valuation_quarter
    from lagged_values
)

select * from returns
