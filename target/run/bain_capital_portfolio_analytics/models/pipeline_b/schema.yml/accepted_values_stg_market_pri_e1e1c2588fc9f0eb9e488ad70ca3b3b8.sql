
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with all_values as (

    select
        trend_signal as value_field,
        count(*) as n_records

    from BAIN_ANALYTICS.DEV.stg_market_prices
    group by trend_signal

)

select *
from all_values
where value_field not in (
    'BULLISH','BEARISH','NEUTRAL'
)



  
  
      
    ) dbt_internal_test