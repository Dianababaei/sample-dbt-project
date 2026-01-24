
    
    

select
    benchmark_id as unique_field,
    count(*) as n_records

from BAIN_ANALYTICS.DEV.benchmarks
where benchmark_id is not null
group by benchmark_id
having count(*) > 1


