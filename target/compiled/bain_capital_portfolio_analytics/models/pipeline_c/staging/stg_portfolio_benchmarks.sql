-- Pipeline C: Complex Portfolio Analytics
-- Model: stg_portfolio_benchmarks
-- Description: Mapping of portfolios to their benchmarks

with source as (
    select
        'PF' || lpad(portfolio_id, 3, '0') as portfolio_id,
        'BM' || lpad(benchmark_id, 3, '0') as benchmark_id,
        is_primary,
        created_at
    from BAIN_ANALYTICS.DEV.sample_portfolio_benchmarks
)

select
    portfolio_id,
    benchmark_id,
    is_primary,
    created_at
from source