
    
    

select
    fund_summary_key as unique_field,
    count(*) as n_records

from BAIN_ANALYTICS.DEV.fact_fund_summary
where fund_summary_key is not null
group by fund_summary_key
having count(*) > 1


