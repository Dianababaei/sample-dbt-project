-- Pipeline A: Simple Cashflow Pipeline
-- Model: stg_portfolios
-- Description: Staging model for portfolio master data
-- Optimization: Single-pass filtering with source constraint on portfolio_id (primary key)
-- No deduplication needed; applied status filter directly in source CTE

with source as (
    select
        portfolio_id,
        portfolio_name,
        portfolio_type,
        fund_id,
        status,
        aum_usd
    from {{ source('raw', 'sample_portfolios') }}
    where status = 'ACTIVE'
)

select * from source
