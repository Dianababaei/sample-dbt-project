
    
    

select
    position_snapshot_key as unique_field,
    count(*) as n_records

from BAIN_ANALYTICS.DEV.fact_position_snapshot
where position_snapshot_key is not null
group by position_snapshot_key
having count(*) > 1


