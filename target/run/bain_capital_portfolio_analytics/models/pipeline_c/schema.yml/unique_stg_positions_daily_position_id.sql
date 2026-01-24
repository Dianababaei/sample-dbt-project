
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    position_id as unique_field,
    count(*) as n_records

from BAIN_ANALYTICS.DEV.stg_positions_daily
where position_id is not null
group by position_id
having count(*) > 1



  
  
      
    ) dbt_internal_test