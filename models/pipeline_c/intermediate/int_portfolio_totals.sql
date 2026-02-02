-- Pipeline C: Intermediate Layer
-- int_portfolio_totals.sql
-- Purpose: Shared model for portfolio total values by date

{{ config(
    materialized='view',
    tags=['intermediate', 'pipeline_c'],
    meta={'pipeline': 'c', 'layer': 'intermediate'}
) }}

select
    portfolio_id,
    position_date,
    sum(market_value_usd) as total_portfolio_value
from {{ ref('int_position_returns') }}
group by portfolio_id, position_date
