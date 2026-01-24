
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select broker_id
from BAIN_ANALYTICS.DEV.brokers
where broker_id is null



  
  
      
    ) dbt_internal_test