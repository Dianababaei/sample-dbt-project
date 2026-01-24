
    
    

select
    position_id as unique_field,
    count(*) as n_records

from BAIN_ANALYTICS.DEV.sample_positions_daily
where position_id is not null
group by position_id
having count(*) > 1


