-- Pipeline C: Complex Portfolio Analytics
-- Model: stg_positions_daily
-- Description: Daily position snapshots from source system
--
-- ISSUES FOR ARTEMIS TO OPTIMIZE:
-- 1. Heavy transformations before filtering
-- 2. Unnecessary type conversions
-- 3. Could push filters upstream

with source as (
    select
        position_id,
        'PF' || lpad(portfolio_id, 3, '0') as portfolio_id,
        'SEC' || lpad(security_id, 3, '0') as security_id,
        position_date,
        quantity,
        market_value_usd,
        created_at
    from {{ source('raw', 'sample_positions_daily') }}
),

-- ISSUE: Transformations applied to all rows before filter
transformed as (
    select
        position_id,
        portfolio_id,
        security_id,
        cast(position_date as date) as position_date,
        cast(quantity as decimal(18,6)) as quantity,
        cast(market_value_usd as decimal(18,2)) as market_value_usd,
        created_at
    from source
),

-- ISSUE: Filter applied last
filtered as (
    select *
    from transformed
    where position_date >= '{{ var("start_date") }}'
)

select * from filtered
