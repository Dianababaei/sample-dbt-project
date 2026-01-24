
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with all_values as (

    select
        trade_category as value_field,
        count(*) as n_records

    from BAIN_ANALYTICS.DEV.stg_trades
    group by trade_category

)

select *
from all_values
where value_field not in (
    'PURCHASE','SALE','INCOME','OTHER'
)



  
  
      
    ) dbt_internal_test