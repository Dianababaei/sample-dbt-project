
  create or replace   view BAIN_ANALYTICS.DEV.stg_benchmarks
  
  
  
  
  as (
    -- Pipeline C: Complex Portfolio Analytics
-- Model: stg_benchmarks
-- Description: Benchmark index data for performance comparison

with source as (
    select
        benchmark_id,
        benchmark_name,
        benchmark_ticker,
        benchmark_type,
        currency,
        is_active
    from BAIN_ANALYTICS.DEV.sample_benchmarks
)

select
    benchmark_id,
    trim(benchmark_name) as benchmark_name,
    upper(trim(benchmark_ticker)) as benchmark_ticker,
    upper(benchmark_type) as benchmark_type,
    upper(currency) as currency,
    is_active
from source
where is_active = true
  );

