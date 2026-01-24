
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select position_key
from BAIN_ANALYTICS.DEV.fact_portfolio_positions
where position_key is null



  
  
      
    ) dbt_internal_test