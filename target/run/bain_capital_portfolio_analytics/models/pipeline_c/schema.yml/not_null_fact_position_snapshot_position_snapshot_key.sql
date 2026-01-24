
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select position_snapshot_key
from BAIN_ANALYTICS.DEV.fact_position_snapshot
where position_snapshot_key is null



  
  
      
    ) dbt_internal_test