-- Pipeline C: Complex Portfolio Analytics
-- Model: stg_valuations
-- Description: Portfolio valuation data (NAV, etc.)
--
-- ISSUES FOR ARTEMIS TO OPTIMIZE:
-- 1. Deduplication via subquery
-- 2. Heavy calculations before filtering

with source as (
    select
        valuation_id,
        'PF' || lpad(portfolio_id, 3, '0') as portfolio_id,
        valuation_date,
        nav,
        nav_usd,
        created_at
    from BAIN_ANALYTICS.DEV.sample_valuations
),

-- ISSUE: Filter applied after deduplication
filtered as (
    select
        valuation_id,
        portfolio_id,
        cast(valuation_date as date) as valuation_date,
        cast(nav as decimal(18,2)) as nav,
        cast(nav_usd as decimal(18,2)) as nav_usd,
        created_at
    from source
    where valuation_date >= '2020-01-01'
)

select * from filtered