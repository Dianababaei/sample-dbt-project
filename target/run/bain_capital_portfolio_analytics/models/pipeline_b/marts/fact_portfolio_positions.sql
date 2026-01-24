
  
    

create or replace transient table BAIN_ANALYTICS.DEV.fact_portfolio_positions
    
    
    
    as (-- Pipeline B: Trade Analytics Pipeline
-- Model: fact_portfolio_positions
-- Description: Current position snapshot by portfolio and security
--
-- ISSUES FOR ARTEMIS TO OPTIMIZE:
-- 1. Gets latest position via subquery (should use QUALIFY)
-- 2. Redundant calculations
-- 3. Multiple passes for final aggregation

with  __dbt__cte__int_trades_enriched as (
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
),  __dbt__cte__int_trade_pnl as (
-- Pipeline B: Trade Analytics Pipeline
-- Model: int_trade_pnl
-- Description: Calculate P&L for each trade
--
-- ISSUES FOR ARTEMIS TO OPTIMIZE:
-- 1. Complex position tracking logic that could be simplified
-- 2. Multiple self-joins for cost basis calculation
-- 3. Window functions recalculated multiple times

with trades as (
    select * from __dbt__cte__int_trades_enriched
),

-- ISSUE: Running position calculation done inefficiently
positions as (
    select
        trade_id,
        portfolio_id,
        security_id,
        ticker,
        trade_date,
        trade_type,
        trade_category,
        quantity,
        execution_price,
        net_amount,
        -- ISSUE: Multiple window functions with same partition
        sum(case
            when trade_category = 'PURCHASE' then quantity
            when trade_category = 'SALE' then -quantity
            else 0
        end) over (
            partition by portfolio_id, security_id
            order by trade_date, trade_id
            rows between unbounded preceding and current row
        ) as running_position,
        sum(case when trade_category = 'PURCHASE' then quantity else 0 end) over (
            partition by portfolio_id, security_id
            order by trade_date, trade_id
            rows between unbounded preceding and current row
        ) as cumulative_purchased_qty,
        sum(case when trade_category = 'PURCHASE' then net_amount else 0 end) over (
            partition by portfolio_id, security_id
            order by trade_date, trade_id
            rows between unbounded preceding and current row
        ) as cumulative_purchase_cost
    from trades
),

-- ISSUE: Separate CTE for cost basis
with_cost_basis as (
    select
        *,
        case
            when cumulative_purchased_qty > 0
            then cumulative_purchase_cost / cumulative_purchased_qty
            else null
        end as avg_cost_basis
    from positions
),

-- ISSUE: Another pass for realized P&L
with_pnl as (
    select
        *,
        case
            when trade_category = 'SALE' and avg_cost_basis is not null
            then (execution_price - avg_cost_basis) * quantity
            else null
        end as realized_pnl,
        case
            when trade_category = 'SALE' and avg_cost_basis is not null and avg_cost_basis > 0
            then (execution_price - avg_cost_basis) / avg_cost_basis * 100
            else null
        end as realized_pnl_pct
    from with_cost_basis
)

select * from with_pnl
), trade_pnl as (
    select * from __dbt__cte__int_trade_pnl
),

-- ISSUE: Using subquery + WHERE instead of QUALIFY for latest
latest_positions as (
    select *
    from (
        select
            *,
            row_number() over (
                partition by portfolio_id, security_id
                order by trade_date desc, trade_id desc
            ) as rn
        from trade_pnl
    )
    where rn = 1
),

market_prices as (
    select
        security_id,
        close_price as current_price,
        price_date
    from (
        select
            security_id,
            close_price,
            price_date,
            row_number() over (partition by security_id order by price_date desc) as rn
        from BAIN_ANALYTICS.DEV.stg_market_prices
    )
    where rn = 1  -- ISSUE: Again, should use QUALIFY
),

-- ISSUE: Final join and calculations that could be simplified
final as (
    select
        md5(cast(coalesce(cast(lp.portfolio_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(lp.security_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as position_key,
        lp.portfolio_id,
        lp.security_id,
        lp.ticker,
        lp.running_position as current_quantity,
        lp.avg_cost_basis,
        mp.current_price,
        mp.price_date as price_as_of_date,
        lp.running_position * lp.avg_cost_basis as cost_basis_value,
        lp.running_position * mp.current_price as market_value,
        (lp.running_position * mp.current_price) - (lp.running_position * lp.avg_cost_basis) as unrealized_pnl,
        case
            when lp.avg_cost_basis > 0
            then ((mp.current_price - lp.avg_cost_basis) / lp.avg_cost_basis) * 100
            else null
        end as unrealized_pnl_pct,
        lp.cumulative_purchase_cost as total_invested,
        current_timestamp() as snapshot_timestamp
    from latest_positions lp
    left join market_prices mp
        on lp.security_id = mp.security_id
    where lp.running_position != 0
)

select * from final
    )
;


  