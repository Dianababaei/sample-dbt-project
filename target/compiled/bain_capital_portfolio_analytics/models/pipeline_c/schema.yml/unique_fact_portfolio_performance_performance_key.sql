
    
    

select
    performance_key as unique_field,
    count(*) as n_records

from BAIN_ANALYTICS.DEV.fact_portfolio_performance
where performance_key is not null
group by performance_key
having count(*) > 1


