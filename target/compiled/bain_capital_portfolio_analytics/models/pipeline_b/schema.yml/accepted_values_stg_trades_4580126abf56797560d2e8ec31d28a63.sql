
    
    

with all_values as (

    select
        trade_category as value_field,
        count(*) as n_records

    from BAIN_ANALYTICS.DEV.stg_trades
    group by trade_category

)

select *
from all_values
where value_field not in (
    'PURCHASE','SALE','INCOME','OTHER'
)


