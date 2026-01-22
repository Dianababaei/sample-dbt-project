-- Pipeline B: Trade Analytics Pipeline
-- Model: fact_trade_summary
-- Description: Fact table for trade-level analysis
--
-- ISSUES FOR ARTEMIS TO OPTIMIZE:
-- 1. Re-joins data that's already joined upstream
-- 2. Aggregations that should be pushed upstream
-- 3. Repeated calculations

with trade_pnl as (
    select * from {{ ref('int_trade_pnl') }}
),

-- ISSUE: Getting portfolio data again (already available through joins upstream)
portfolios as (
    select * from {{ ref('stg_portfolios') }}
),

-- ISSUE: Another join that adds overhead
final as (
    select
        {{ dbt_utils.generate_surrogate_key(['t.trade_id']) }} as trade_key,
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
