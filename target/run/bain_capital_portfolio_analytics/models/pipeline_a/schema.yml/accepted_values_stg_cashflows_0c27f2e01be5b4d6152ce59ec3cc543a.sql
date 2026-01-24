
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with all_values as (

    select
        cashflow_type as value_field,
        count(*) as n_records

    from BAIN_ANALYTICS.DEV.stg_cashflows
    group by cashflow_type

)

select *
from all_values
where value_field not in (
    'CONTRIBUTION','DISTRIBUTION','DIVIDEND','FEE'
)



  
  
      
    ) dbt_internal_test