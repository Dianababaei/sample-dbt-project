
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with all_values as (

    select
        security_type_standardized as value_field,
        count(*) as n_records

    from BAIN_ANALYTICS.DEV.stg_securities
    group by security_type_standardized

)

select *
from all_values
where value_field not in (
    'EQUITY','FIXED_INCOME','DERIVATIVE','FUND','OTHER'
)



  
  
      
    ) dbt_internal_test