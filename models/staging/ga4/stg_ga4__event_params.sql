{{
  config(
    materialized='view'
  )
}}

with source as (

    select
        user_pseudo_id,
        event_name,
        event_timestamp,
        event_date,
        event_params,
        _table_suffix as table_suffix
    from {{ source('ga4', 'events') }}
    where _table_suffix >= '{{ var("ga4_start_date") }}'

),

flattened as (

    select
        user_pseudo_id,
        event_name,
        {{ safe_timestamp('event_timestamp') }} as event_timestamp,
        cast(parse_date('%Y%m%d', event_date) as date) as event_date,
        param.key as param_key,
        param.value.string_value as param_string_value,
        param.value.int_value as param_int_value,
        param.value.float_value as param_float_value,
        param.value.double_value as param_double_value,
        coalesce(
            param.value.string_value,
            cast(param.value.int_value as string),
            cast(param.value.float_value as string),
            cast(param.value.double_value as string)
        ) as param_value,
        table_suffix as event_date_suffix
    from source,
    unnest(event_params) as param

)

select * from flattened
