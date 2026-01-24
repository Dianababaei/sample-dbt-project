
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    benchmark_id as unique_field,
    count(*) as n_records

from BAIN_ANALYTICS.DEV.benchmarks
where benchmark_id is not null
group by benchmark_id
having count(*) > 1



  
  
      
    ) dbt_internal_test