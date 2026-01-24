
    
    

select
    portfolio_id as unique_field,
    count(*) as n_records

from BAIN_ANALYTICS.DEV.sample_portfolios
where portfolio_id is not null
group by portfolio_id
having count(*) > 1


