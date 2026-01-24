
    
    

select
    entity_id as unique_field,
    count(*) as n_records

from BAIN_ANALYTICS.DEV.fund_hierarchy
where entity_id is not null
group by entity_id
having count(*) > 1


