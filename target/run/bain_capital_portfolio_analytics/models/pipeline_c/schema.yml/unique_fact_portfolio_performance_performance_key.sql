
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    performance_key as unique_field,
    count(*) as n_records

from BAIN_ANALYTICS.DEV.fact_portfolio_performance
where performance_key is not null
group by performance_key
having count(*) > 1



  
  
      
    ) dbt_internal_test