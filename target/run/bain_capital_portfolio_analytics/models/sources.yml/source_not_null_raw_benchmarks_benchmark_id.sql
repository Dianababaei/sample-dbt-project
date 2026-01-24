
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select benchmark_id
from BAIN_ANALYTICS.DEV.benchmarks
where benchmark_id is null



  
  
      
    ) dbt_internal_test