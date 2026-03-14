{{
  config(
    materialized='incremental',
    unique_key='event_surrogate_key',
    partition_by={
      "field": "event_date",
      "data_type": "date",
      "granularity": "day"
    },
    cluster_by=['event_name', 'user_pseudo_id']
  )
}}

{#
  Conversion events fact table.
  Filters to only events defined as conversions in the project vars.
  Enriched with session context and traffic attribution.
#}

with session_events as (

    select * from {{ ref('int_ga4__session_events') }}
    where is_conversion_event = true

),

user_stitching as (

    select * from {{ ref('int_ga4__user_stitching') }}

),

final as (

    select
        e.event_surrogate_key,
        e.event_name,
        e.event_timestamp,
        e.event_date,
        e.user_pseudo_id,
        coalesce(u.stitched_user_id, e.user_id) as user_id,
        coalesce(u.stitched_user_id, e.user_pseudo_id) as unified_user_id,

        -- Session context
        e.session_key,
        e.ga_session_id,
        e.ga_session_number,
        e.is_first_session,

        -- Conversion details
        e.event_value,
        e.transaction_id,
        e.ecommerce_purchase_revenue_usd,
        e.ecommerce_transaction_id,
        e.coupon,
        e.payment_type,

        -- Attribution
        e.resolved_source as source,
        e.resolved_medium as medium,
        e.resolved_campaign as campaign,
        e.event_term as term,
        e.event_content as content,

        {{ default_channel_grouping(
            'e.resolved_source',
            'e.resolved_medium',
            'e.resolved_campaign'
        ) }} as default_channel_grouping,

        -- Page context
        e.page_location,
        e.page_title,

        -- Device & geo
        e.device_category,
        e.device_os,
        e.device_browser,
        e.geo_country,
        e.geo_region,
        e.geo_city,
        e.platform

    from session_events e
    left join user_stitching u
        on e.user_pseudo_id = u.user_pseudo_id

)

select * from final

{% if is_incremental() %}
where event_date >= (select max(event_date) from {{ this }}) - interval 3 day
{% endif %}
