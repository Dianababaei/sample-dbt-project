-- Pipeline B: Trade Analytics Pipeline
-- Model: stg_market_prices
-- Description: Staging model for daily market prices
--
-- ISSUES FOR ARTEMIS TO OPTIMIZE:
-- 1. Self-join for prior day prices (inefficient)
-- 2. Late aggregation
-- 3. Multiple window functions that could be consolidated

with source as (
    select
        security_id,
        price_date,
        close_price,
        volume,
        created_at
    from BAIN_ANALYTICS.DEV.sample_market_prices
    where price_date >= '2020-01-01'
),

-- ISSUE: Multiple separate window functions
with_returns as (
    select
        *,
        -- ISSUE: These could be computed together
        avg(close_price) over (
            partition by security_id
            order by price_date
            rows between 19 preceding and current row
        ) as ma_20,
        avg(close_price) over (
            partition by security_id
            order by price_date
            rows between 49 preceding and current row
        ) as ma_50,
        avg(volume) over (
            partition by security_id
            order by price_date
            rows between 19 preceding and current row
        ) as avg_volume_20d
    from source
),

-- ISSUE: Another pass for more calculations
final as (
    select
        *,
        case
            when volume > avg_volume_20d * 2 then 'HIGH'
            when volume < avg_volume_20d * 0.5 then 'LOW'
            else 'NORMAL'
        end as volume_signal
    from with_returns
)

select * from final