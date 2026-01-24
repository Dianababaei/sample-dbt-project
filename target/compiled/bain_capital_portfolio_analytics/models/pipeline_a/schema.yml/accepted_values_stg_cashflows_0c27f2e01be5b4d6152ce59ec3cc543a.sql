
    
    

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


