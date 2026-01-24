
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select portfolio_id
from BAIN_ANALYTICS.DEV.int_portfolio_returns_daily
where portfolio_id is null



  
  
      
    ) dbt_internal_test