-- Pipeline B: Intermediate Layer
-- int_trade_execution_analysis.sql
-- Purpose: Advanced trade execution analysis with market impact and execution costs

{{ config(
    materialized='view',
    tags=['intermediate', 'pipeline_b'],
    meta={'pipeline': 'b', 'layer': 'intermediate'}
) }}

with trades_detail as (
    select * from {{ ref('int_trade_metrics') }}
),

execution_with_windows as (
    select
        td.*,
        avg(price) over (partition by trade_date, security_id) as daily_avg_price,
        min(price) over (partition by trade_date, security_id) as daily_min_price,
        max(price) over (partition by trade_date, security_id) as daily_max_price,
        max(price) - min(price) over (partition by trade_date, security_id) as daily_price_range,
        stddev_pop(price) over (partition by trade_date, security_id) as daily_volatility
    from trades_detail td
)

select
    trade_id,
    trade_date,
    portfolio_id,
    security_id,
    ticker,
    quantity,
    price as execution_price,
    trade_value,
    commission,
    daily_avg_price,
    daily_min_price,
    daily_max_price,
    daily_price_range,
    daily_volatility,
    round((price - daily_min_price) / nullif(daily_price_range, 0), 8) as execution_percentile,
    round(100 * (price - daily_avg_price) / nullif(daily_avg_price, 0), 4) as price_vs_avg_pct,
    case
        when (price - daily_min_price) / nullif(daily_price_range, 0) > 0.75 then 'POOR'
        when (price - daily_min_price) / nullif(daily_price_range, 0) > 0.50 then 'FAIR'
        when (price - daily_min_price) / nullif(daily_price_range, 0) > 0.25 then 'GOOD'
        else 'EXCELLENT'
    end as execution_quality,
    round(commission / nullif(trade_value, 0), 8) as commission_ratio,
    round(100 * commission / nullif(trade_value, 0), 6) as commission_ratio_bps
from execution_with_windows
