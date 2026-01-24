
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select trade_key
from BAIN_ANALYTICS.DEV.fact_trade_summary
where trade_key is null



  
  
      
    ) dbt_internal_test