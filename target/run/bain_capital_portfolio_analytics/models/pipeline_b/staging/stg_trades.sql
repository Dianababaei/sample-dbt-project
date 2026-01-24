
  create or replace   view BAIN_ANALYTICS.DEV.stg_trades
  
  
  
  
  as (
    -- Pipeline B: Trade Analytics Pipeline
-- Model: stg_trades
-- Description: Staging model for trade transactions
--
-- ISSUES FOR ARTEMIS TO OPTIMIZE:
-- 1. Complex CASE statements that repeat
-- 2. Multiple CTEs doing similar transformations
-- 3. Unnecessary string operations

with source as (
    select
        trade_id,
        'PF' || lpad(portfolio_id, 3, '0') as portfolio_id,
        'SEC' || lpad(security_id, 3, '0') as security_id,
        trade_date,
        trade_type,
        quantity,
        price,
        net_amount,
        broker_id,
        created_at
    from BAIN_ANALYTICS.DEV.sample_trades
),

-- ISSUE: Repeated CASE statements for trade categorization
categorized as (
    select
        *,
        -- ISSUE: This logic is repeated in multiple models
        case
            when trade_type in ('BUY', 'COVER') then 'PURCHASE'
            when trade_type in ('SELL', 'SHORT') then 'SALE'
            when trade_type in ('DIVIDEND', 'INTEREST') then 'INCOME'
            else 'OTHER'
        end as trade_category,
        case
            when abs(net_amount) >= 10000000 then 'LARGE'
            when abs(net_amount) >= 1000000 then 'MEDIUM'
            when abs(net_amount) >= 100000 then 'SMALL'
            else 'MICRO'
        end as trade_size_bucket,
        -- ISSUE: Redundant string manipulation
        upper(trim(trade_type)) as trade_type_clean
    from source
),

-- ISSUE: Another pass just for date calculations
with_dates as (
    select
        *,
        date_trunc('month', trade_date) as trade_month,
        date_trunc('quarter', trade_date) as trade_quarter,
        extract(year from trade_date) as trade_year,
        extract(month from trade_date) as trade_month_num,
        dayofweek(trade_date) as trade_day_of_week
    from categorized
),

-- ISSUE: Late filtering
filtered as (
    select *
    from with_dates
    where trade_date >= '2020-01-01'
)

select * from filtered
  );

