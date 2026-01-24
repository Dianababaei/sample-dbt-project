
  
    

create or replace transient table BAIN_ANALYTICS.DEV.fact_trade_summary
    
    
    
    as (-- Pipeline B: Trade Analytics Pipeline
-- Model: fact_trade_summary
-- Description: Fact table for trade-level analysis
--
-- ISSUES FOR ARTEMIS TO OPTIMIZE:
-- 1. Re-joins data that's already joined upstream
-- 2. Aggregations that should be pushed upstream
-- 3. Repeated calculations

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

-- ISSUE: Getting portfolio data again (already available through joins upstream)
portfolios as (
    select * from BAIN_ANALYTICS.DEV.stg_portfolios
),

-- ISSUE: Another join that adds overhead
final as (
    select
        md5(cast(coalesce(cast(t.trade_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as trade_key,
        t.trade_id,
        t.portfolio_id,
        p.portfolio_name,
        p.portfolio_type,
        p.fund_id,
        t.security_id,
        t.ticker,
        t.trade_date,
        t.trade_type,
        t.trade_category,
        t.quantity,
        t.execution_price,
        t.net_amount,
        t.running_position,
        t.avg_cost_basis,
        t.realized_pnl,
        t.realized_pnl_pct,
        -- ISSUE: Redundant date extractions (already done upstream)
        extract(year from t.trade_date) as trade_year,
        extract(month from t.trade_date) as trade_month,
        extract(quarter from t.trade_date) as trade_quarter,
        date_trunc('week', t.trade_date) as trade_week
    from trade_pnl t
    left join portfolios p
        on t.portfolio_id = p.portfolio_id
)

select * from final
    )
;


  