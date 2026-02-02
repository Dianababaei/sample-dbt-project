-- Pipeline C: Intermediate Layer
-- int_portfolio_totals.sql

{{ config(
    materialized='view',
    tags=['intermediate', 'pipeline_c'],
    meta={'pipeline': 'c', 'layer': 'intermediate'}
) }}

with position_returns as (
    select * from {{ ref('int_position_returns') }}
),

portfolio_totals as (
    select
        portfolio_id,
        position_date,
        sum(market_value_usd) as total_portfolio_value,
        sum(daily_pnl) as total_portfolio_pnl
    from position_returns
    group by portfolio_id, position_date
)

select * from portfolio_totals
