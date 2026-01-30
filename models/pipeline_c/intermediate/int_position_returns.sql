-- Pipeline C: Intermediate Layer
-- int_position_returns.sql

{{
  config(
    materialized='incremental',
    unique_key='position_id',
    incremental_strategy='merge',
    tags=['intermediate', 'pipeline_c'],
    meta={'pipeline': 'c', 'layer': 'intermediate'}
  )
}}

with enriched as (
    select * from {{ ref('int_position_enriched') }}
    {% if execute and is_incremental() %}
        where position_date >= (select max(position_date) from {{ this }}) - interval '7 days'
    {% endif %}
),

cast_enriched as (
    select
        cast(position_id as varchar) as position_id,
        cast(portfolio_id as varchar) as portfolio_id,
        cast(security_id as varchar) as security_id,
        cast(position_date as date) as position_date,
        cast(quantity as numeric(18, 2)) as quantity,
        cast(market_value_usd as numeric(18, 2)) as market_value_usd,
        cast(ticker as varchar) as ticker,
        cast(security_name as varchar) as security_name,
        cast(asset_class as varchar) as asset_class,
        cast(sector as varchar) as sector
    from enriched
),

with_lag as (
    select
        position_id,
        portfolio_id,
        security_id,
        position_date,
        quantity,
        market_value_usd,
        ticker,
        security_name,
        asset_class,
        sector,
        lag(market_value_usd) over (partition by security_id order by position_date) as prev_market_value
    from cast_enriched
),

returns as (
    select
        position_id,
        portfolio_id,
        security_id,
        position_date,
        quantity,
        market_value_usd,
        ticker,
        security_name,
        asset_class,
        sector,
        prev_market_value as prev_value,
        market_value_usd - prev_market_value as daily_pnl,
        case
            when prev_market_value > 0
            then (market_value_usd - prev_market_value) / prev_market_value
            else 0
        end as daily_return_pct
    from with_lag
)

select * from returns
