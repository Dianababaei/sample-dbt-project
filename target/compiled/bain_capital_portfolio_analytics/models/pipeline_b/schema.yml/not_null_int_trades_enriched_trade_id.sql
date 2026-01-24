
    
    



with __dbt__cte__int_trades_enriched as (
-- Pipeline B: Trade Analytics Pipeline
-- Model: int_trades_enriched
-- Description: Intermediate model enriching trades with security and price data
--
-- ISSUES FOR ARTEMIS TO OPTIMIZE:
-- 1. Multiple heavy joins done row-by-row
-- 2. Price lookup repeated for every trade
-- 3. Could pre-aggregate before joining

with trades as (
    select * from BAIN_ANALYTICS.DEV.stg_trades
),

securities as (
    select * from BAIN_ANALYTICS.DEV.stg_securities
),

market_prices as (
    select * from BAIN_ANALYTICS.DEV.stg_market_prices
),

brokers as (
    select * from BAIN_ANALYTICS.DEV.stg_brokers
),

-- ISSUE: Heavy multi-way join before any aggregation
enriched as (
    select
        t.trade_id,
        t.portfolio_id,
        t.security_id,
        t.trade_date,
        t.trade_type,
        t.trade_category,
        t.trade_size_bucket,
        t.quantity,
        t.price as execution_price,
        t.net_amount,
        t.currency,
        t.trade_month,
        t.trade_quarter,
        t.trade_year,
        t.trade_type_clean,
        -- Security attributes
        s.ticker,
        s.security_name,
        s.security_type_standardized as security_type,
        s.asset_class,
        s.sector,
        s.industry,
        s.country as security_country,
        -- Broker attributes
        b.broker_name,
        b.created_at as broker_created_at
    from trades t
    inner join securities s
        on t.security_id = s.security_id
    left join brokers b
        on t.broker_id = b.broker_id
)

select * from enriched
) select trade_id
from __dbt__cte__int_trades_enriched
where trade_id is null


