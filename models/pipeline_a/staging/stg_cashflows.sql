-- Pipeline A: Staging Layer
-- stg_cashflows.sql
-- Purpose: Clean and standardize cashflow transaction data
-- Models downstream: 1 (int_cashflow_aggregated)

{{ config(
    materialized='table',
    tags=['staging', 'pipeline_a'],
    meta={'pipeline': 'a', 'layer': 'staging'}
) }}

select
    portfolio_id,
    cashflow_date,
    cashflow_type,
    amount,
    currency
from {{ source('raw', 'sample_cashflows') }}
where amount <> 0
