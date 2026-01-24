-- Pipeline C: Complex Portfolio Analytics
-- Model: int_sector_attribution
-- Description: Aggregate attribution to sector level
--
-- ISSUES FOR ARTEMIS TO OPTIMIZE:
-- 1. Re-aggregation of position data
-- 2. Complex grouping logic
-- 3. Could be combined with position attribution

with position_attribution as (
    select * from {{ ref('int_position_attribution') }}
),

-- ISSUE: Aggregation that could be pushed upstream
sector_daily as (
    select
        portfolio_id,
        position_date,
        sector,
        count(distinct security_id) as position_count,
        sum(market_value_usd) as sector_market_value,
        sum(position_pnl) as sector_pnl
    from position_attribution
    group by 1, 2, 3
),

-- ISSUE: Window functions for rolling metrics
with_rolling as (
    select
        *,
        sum(sector_pnl) over (
            partition by portfolio_id, sector
            order by position_date
            rows between 29 preceding and current row
        ) as sector_pnl_30d,
        lag(sector_market_value, 1) over (
            partition by portfolio_id, sector
            order by position_date
        ) as prior_sector_market_value
    from sector_daily
)

select * from with_rolling
