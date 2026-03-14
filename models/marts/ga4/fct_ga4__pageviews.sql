{{
  config(
    materialized='incremental',
    unique_key='event_surrogate_key',
    partition_by={
      "field": "event_date",
      "data_type": "date",
      "granularity": "day"
    },
    cluster_by=['user_pseudo_id', 'page_location']
  )
}}

{#
  Pageview-level fact table.
  One row per page_view event with time-on-page approximation,
  session context, and traffic attribution.
#}

with pageviews as (

    select * from {{ ref('int_ga4__session_events') }}
    where event_name = 'page_view'

),

user_stitching as (

    select * from {{ ref('int_ga4__user_stitching') }}

),

with_time_on_page as (

    select
        p.*,
        coalesce(u.stitched_user_id, p.user_id) as resolved_user_id,
        coalesce(u.stitched_user_id, p.user_pseudo_id) as unified_user_id,

        -- Approximate time-on-page using next pageview timestamp
        lead(p.event_timestamp) over (
            partition by p.user_pseudo_id, p.ga_session_id
            order by p.event_timestamp
        ) as next_pageview_at,

        timestamp_diff(
            lead(p.event_timestamp) over (
                partition by p.user_pseudo_id, p.ga_session_id
                order by p.event_timestamp
            ),
            p.event_timestamp,
            second
        ) as time_on_page_sec

    from pageviews p
    left join user_stitching u
        on p.user_pseudo_id = u.user_pseudo_id

),

final as (

    select
        event_surrogate_key,
        event_timestamp,
        event_date,
        user_pseudo_id,
        resolved_user_id as user_id,
        unified_user_id,

        -- Session context
        session_key,
        ga_session_id,
        ga_session_number,
        is_first_session,
        session_pageview_count,

        -- Page details
        page_location,
        page_title,
        page_referrer,
        entrances,

        -- Time on page
        time_on_page_sec,
        coalesce(engagement_time_msec, 0) as engagement_time_msec,

        -- Attribution
        resolved_source as source,
        resolved_medium as medium,
        resolved_campaign as campaign,

        {{ default_channel_grouping(
            'resolved_source',
            'resolved_medium',
            'resolved_campaign'
        ) }} as default_channel_grouping,

        -- Device & geo
        device_category,
        device_os,
        device_browser,
        geo_country,
        geo_region,
        geo_city,
        platform

    from with_time_on_page

)

select * from final

{% if is_incremental() %}
where event_date >= (select max(event_date) from {{ this }}) - interval 3 day
{% endif %}
