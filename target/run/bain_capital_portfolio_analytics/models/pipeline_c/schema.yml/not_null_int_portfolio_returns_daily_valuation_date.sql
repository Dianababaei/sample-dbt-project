
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select valuation_date
from BAIN_ANALYTICS.DEV.int_portfolio_returns_daily
where valuation_date is null



  
  
      
    ) dbt_internal_test