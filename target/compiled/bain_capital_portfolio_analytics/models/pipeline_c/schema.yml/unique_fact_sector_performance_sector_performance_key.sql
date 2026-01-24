
    
    

select
    sector_performance_key as unique_field,
    count(*) as n_records

from BAIN_ANALYTICS.DEV.fact_sector_performance
where sector_performance_key is not null
group by sector_performance_key
having count(*) > 1


