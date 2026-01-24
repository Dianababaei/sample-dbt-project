
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select position_id
from BAIN_ANALYTICS.DEV.stg_positions_daily
where position_id is null



  
  
      
    ) dbt_internal_test