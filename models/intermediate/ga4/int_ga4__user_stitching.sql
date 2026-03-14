{{
  config(
    materialized='ephemeral'
  )
}}

{#
  User identity stitching.
  
  Maps user_pseudo_id (anonymous) to user_id (authenticated) by finding
  the most recent non-null user_id set for each user_pseudo_id. This allows
  downstream models to use a unified user key.
#}

with user_ids as (

    select
        user_pseudo_id,
        user_id,
        event_timestamp,
        row_number() over (
            partition by user_pseudo_id
            order by event_timestamp desc
        ) as rn
    from {{ ref('stg_ga4__events') }}
    where user_id is not null

),

stitched as (

    select
        user_pseudo_id,
        user_id as stitched_user_id
    from user_ids
    where rn = 1

)

select * from stitched
