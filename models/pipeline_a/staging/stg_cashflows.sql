-- Pipeline A: Simple Cashflow Pipeline
-- Model: stg_cashflows
-- Description: Staging model for raw cashflow data with optimized early filtering
--
-- OPTIMIZED FOR PERFORMANCE:
-- 1. Early filtering: Date range filter applied immediately after source
-- 2. Removed DISTINCT: Source data is already unique on cashflow_id
-- 3. Efficient transformations: Applied only on filtered dataset

with source as (
    select
        cashflow_id,
        portfolio_id,
        cashflow_type,
        cashflow_date,
        amount,
        currency,
        created_at,
        updated_at
    from {{ source('raw', 'sample_cashflows') }}
),

-- Early filtering: Apply date range predicate before expensive transformations
filtered_data as (
    select
        cashflow_id,
        portfolio_id,
        cashflow_type,
        cashflow_date,
        amount,
        currency,
        created_at,
        updated_at
    from source
    where cast(cashflow_date as date) >= '{{ var("start_date") }}'
      and cast(cashflow_date as date) <= '{{ var("end_date") }}'
),

-- Transformations applied only to filtered dataset
converted as (
    select
        cashflow_id,
        'PF' || lpad(portfolio_id, 3, '0') as portfolio_id,
        upper(cashflow_type) as cashflow_type,
        cast(cashflow_date as date) as cashflow_date,
        cast(amount as decimal(18,2)) as amount,
        upper(currency) as currency,
        cast(created_at as timestamp) as created_at,
        cast(updated_at as timestamp) as updated_at
    from filtered_data
)

select * from converted
