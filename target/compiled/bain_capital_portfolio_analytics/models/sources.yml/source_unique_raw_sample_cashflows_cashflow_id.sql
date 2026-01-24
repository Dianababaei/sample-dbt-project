
    
    

select
    cashflow_id as unique_field,
    count(*) as n_records

from BAIN_ANALYTICS.DEV.sample_cashflows
where cashflow_id is not null
group by cashflow_id
having count(*) > 1


