
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select portfolio_id
from BAIN_ANALYTICS.DEV.report_trading_performance
where portfolio_id is null



  
  
      
    ) dbt_internal_test