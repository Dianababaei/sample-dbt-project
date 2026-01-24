-- Pipeline B: Trade Analytics Pipeline
-- Model: stg_securities
-- Description: Staging model for security master data
--
-- ISSUES FOR ARTEMIS TO OPTIMIZE:
-- 1. Nested subqueries instead of QUALIFY
-- 2. Multiple deduplication passes

with source as (
    select
        security_id,
        ticker,
        security_name,
        security_type,
        asset_class,
        sector,
        industry,
        country,
        currency
    from BAIN_ANALYTICS.DEV.sample_securities
),

-- ISSUE: Separate CTE for type standardization
standardized as (
    select
        security_id,
        upper(trim(ticker)) as ticker,
        trim(security_name) as security_name,
        -- ISSUE: Repeated CASE logic found in other models
        case
            when security_type in ('STOCK', 'EQUITY', 'COMMON') then 'EQUITY'
            when security_type in ('BOND', 'NOTE', 'DEBENTURE') then 'FIXED_INCOME'
            when security_type in ('OPTION', 'FUTURE', 'SWAP') then 'DERIVATIVE'
            when security_type in ('ETF', 'MUTUAL_FUND') then 'FUND'
            else 'OTHER'
        end as security_type_standardized,
        security_type as security_type_original,
        upper(asset_class) as asset_class,
        sector,
        industry,
        upper(country) as country,
        upper(currency) as currency
    from source
)

select * from standardized