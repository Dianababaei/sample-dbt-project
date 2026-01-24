
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    trade_key as unique_field,
    count(*) as n_records

from BAIN_ANALYTICS.DEV.fact_trade_summary
where trade_key is not null
group by trade_key
having count(*) > 1



  
  
      
    ) dbt_internal_test