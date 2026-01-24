
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    position_snapshot_key as unique_field,
    count(*) as n_records

from BAIN_ANALYTICS.DEV.fact_position_snapshot
where position_snapshot_key is not null
group by position_snapshot_key
having count(*) > 1



  
  
      
    ) dbt_internal_test