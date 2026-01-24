
    
    

select
    trade_id as unique_field,
    count(*) as n_records

from BAIN_ANALYTICS.DEV.fact_trade_summary
where trade_id is not null
group by trade_id
having count(*) > 1


