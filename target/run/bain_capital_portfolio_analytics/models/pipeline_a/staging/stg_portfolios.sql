
  create or replace   view BAIN_ANALYTICS.DEV.stg_portfolios
  
  
  
  
  as (
    -- Pipeline A: Simple Cashflow Pipeline
-- Model: stg_portfolios
-- Description: Staging model for portfolio master data
--
-- ISSUES FOR ARTEMIS TO OPTIMIZE:
-- 1. Subquery for deduplication instead of QUALIFY
-- 2. Multiple passes over data

with source as (
    select
        portfolio_id,
        portfolio_name,
        portfolio_type,
        fund_id,
        status,
        aum_usd
    from BAIN_ANALYTICS.DEV.sample_portfolios
),

active_only as (
    select *
    from source
    where status = 'ACTIVE'
)

select * from active_only
  );

