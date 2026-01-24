
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select sector_performance_key
from BAIN_ANALYTICS.DEV.fact_sector_performance
where sector_performance_key is null



  
  
      
    ) dbt_internal_test