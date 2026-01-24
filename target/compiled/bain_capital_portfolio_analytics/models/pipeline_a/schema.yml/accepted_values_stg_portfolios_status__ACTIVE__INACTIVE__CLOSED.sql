
    
    

with all_values as (

    select
        status as value_field,
        count(*) as n_records

    from BAIN_ANALYTICS.DEV.stg_portfolios
    group by status

)

select *
from all_values
where value_field not in (
    'ACTIVE','INACTIVE','CLOSED'
)


