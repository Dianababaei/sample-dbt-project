
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select nav_usd
from BAIN_ANALYTICS.DEV.stg_valuations
where nav_usd is null



  
  
      
    ) dbt_internal_test