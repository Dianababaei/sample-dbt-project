
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select amount
from BAIN_ANALYTICS.DEV.stg_cashflows
where amount is null



  
  
      
    ) dbt_internal_test