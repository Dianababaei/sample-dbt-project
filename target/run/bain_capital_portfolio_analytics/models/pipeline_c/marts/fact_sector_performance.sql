
  
    

create or replace transient table BAIN_ANALYTICS.DEV.fact_sector_performance
    
    
    
    as (-- Pipeline C: Complex Portfolio Analytics
-- Model: fact_sector_performance
-- Description: Sector-level performance aggregation
--
-- ISSUES FOR ARTEMIS TO OPTIMIZE:
-- 1. Re-aggregates data from upstream
-- 2. Complex window functions

with sector_attribution as (
    select * from BAIN_ANALYTICS.DEV.int_sector_attribution
),

portfolios as (
    select * from BAIN_ANALYTICS.DEV.stg_portfolios
),

-- ISSUE: Another portfolio join
with_portfolio_info as (
    select
        sa.*,
        p.portfolio_name,
        p.portfolio_type,
        p.fund_id
    from sector_attribution sa
    inner join portfolios p
        on sa.portfolio_id = p.portfolio_id
),

-- ISSUE: More window functions for sector ranking
with_rankings as (
    select
        *,
        rank() over (
            partition by portfolio_id, position_date
            order by sector_weight desc
        ) as sector_weight_rank,
        rank() over (
            partition by portfolio_id, position_date
            order by sector_contribution desc
        ) as sector_contribution_rank
    from with_portfolio_info
),

final as (
    select
        md5(cast(coalesce(cast(portfolio_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(sector as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(position_date as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as sector_performance_key,
        *,
        case
            when sector_weight_rank <= 3 then 'TOP_3'
            when sector_weight_rank <= 5 then 'TOP_5'
            else 'OTHER'
        end as sector_weight_tier
    from with_rankings
)

select * from final
    )
;


  