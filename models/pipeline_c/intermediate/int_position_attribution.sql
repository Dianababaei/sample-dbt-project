-- Pipeline C: Intermediate Layer
-- int_position_attribution.sql
-- Purpose: Analyze position-level contribution to portfolio performance

{{ config(
    materialized='view',
    tags=['intermediate', 'pipeline_c'],
    meta={'pipeline': 'c', 'layer': 'intermediate'}
) }}

with pos_perf as (
    select * from {{ ref('int_position_returns') }}
),

portfolio_totals as (
    select * from {{ ref('int_portfolio_totals') }}
)

select
    pp.position_id,
    pp.portfolio_id,
    pp.security_id,
    pp.position_date,
    pp.ticker,
    pp.security_name,
    pp.asset_class,
    pp.sector,
    pp.market_value_usd,
    pt.total_portfolio_value,
    round(pp.market_value_usd / nullif(pt.total_portfolio_value, 0), 8) as position_weight,
    round(100 * pp.market_value_usd / nullif(pt.total_portfolio_value, 0), 4) as position_weight_pct,
    pp.daily_pnl,
    pp.daily_return_pct,
    round(pp.daily_pnl / nullif(pt.total_portfolio_value, 0), 8) as position_contribution_to_portfolio_pnl,
    round(100 * pp.daily_pnl / nullif(pt.total_portfolio_value, 0), 4) as position_contribution_bps
from pos_perf pp
left join portfolio_totals pt
    on pp.portfolio_id = pt.portfolio_id
    and pp.position_date = pt.position_date
