
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select ticker
from BAIN_ANALYTICS.DEV.stg_securities
where ticker is null



  
  
      
    ) dbt_internal_test