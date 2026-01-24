
    
    

with all_values as (

    select
        trade_size_bucket as value_field,
        count(*) as n_records

    from BAIN_ANALYTICS.DEV.stg_trades
    group by trade_size_bucket

)

select *
from all_values
where value_field not in (
    'LARGE','MEDIUM','SMALL','MICRO'
)


