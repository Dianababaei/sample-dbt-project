
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    cashflow_summary_key as unique_field,
    count(*) as n_records

from BAIN_ANALYTICS.DEV.fact_cashflow_summary
where cashflow_summary_key is not null
group by cashflow_summary_key
having count(*) > 1



  
  
      
    ) dbt_internal_test