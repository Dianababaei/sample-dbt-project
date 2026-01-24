-- Pipeline B: Trade Analytics Pipeline
-- Model: stg_brokers
-- Description: Staging model for broker information

with source as (
    select
        broker_id,
        broker_name,
        created_at
    from {{ source('raw', 'sample_brokers') }}
)

select
    broker_id,
    trim(broker_name) as broker_name,
    created_at
from source
