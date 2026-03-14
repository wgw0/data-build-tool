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
        user_properties,
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
        prop.key as property_key,
        prop.value.string_value as property_string_value,
        prop.value.int_value as property_int_value,
        prop.value.float_value as property_float_value,
        prop.value.double_value as property_double_value,
        {{ safe_timestamp('prop.value.set_timestamp_micros') }} as property_set_at,
        coalesce(
            prop.value.string_value,
            cast(prop.value.int_value as string),
            cast(prop.value.float_value as string),
            cast(prop.value.double_value as string)
        ) as property_value,
        table_suffix as event_date_suffix
    from source,
    unnest(user_properties) as prop

)

select * from flattened
