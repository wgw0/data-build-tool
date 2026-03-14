{{
  config(
    materialized='incremental',
    unique_key='session_key',
    partition_by={
      "field": "session_date",
      "data_type": "date",
      "granularity": "day"
    },
    cluster_by=['user_pseudo_id', 'session_source', 'device_category']
  )
}}

{#
  Session-level fact table.
  One row per session with full attribution, engagement, conversion,
  and ecommerce metrics. Partitioned by date for cost-efficient queries.
#}

with sessions as (

    select * from {{ ref('int_ga4__sessions') }}

),

user_stitching as (

    select * from {{ ref('int_ga4__user_stitching') }}

),

final as (

    select
        s.session_key,
        s.user_pseudo_id,
        coalesce(u.stitched_user_id, s.user_id) as user_id,
        coalesce(u.stitched_user_id, s.user_pseudo_id) as unified_user_id,
        s.ga_session_id,
        s.ga_session_number,

        -- Timestamps
        s.session_start_at,
        s.session_end_at,
        s.session_date,
        s.session_duration_sec,

        -- Engagement
        s.is_engaged_session,
        s.is_first_session,
        s.total_engagement_time_msec,
        s.total_engagement_time_sec,
        s.pageview_count,
        s.event_count,
        s.distinct_event_count,

        -- Pages
        s.landing_page,
        s.landing_page_title,
        s.exit_page,

        -- Traffic source
        coalesce(s.collected_session_source, s.session_source) as session_source,
        coalesce(s.collected_session_medium, s.session_medium) as session_medium,
        coalesce(s.collected_session_campaign, s.session_campaign) as session_campaign,
        s.session_term,
        s.session_content,
        s.collected_session_gclid,
        s.user_traffic_source,
        s.user_traffic_medium,
        s.user_traffic_campaign,

        -- Channel grouping
        {{ default_channel_grouping(
            'coalesce(s.collected_session_source, s.session_source)',
            'coalesce(s.collected_session_medium, s.session_medium)',
            'coalesce(s.collected_session_campaign, s.session_campaign)'
        ) }} as default_channel_grouping,

        -- Device & geo
        s.device_category,
        s.device_os,
        s.device_browser,
        s.device_language,
        s.geo_continent,
        s.geo_country,
        s.geo_region,
        s.geo_city,
        s.platform,

        -- Conversions
        s.conversion_count,
        s.has_conversion,

        -- Ecommerce
        s.session_revenue_usd,
        s.purchase_count,
        s.add_to_cart_count,
        s.begin_checkout_count,
        s.view_item_count,
        s.view_item_list_count,
        s.has_purchase

    from sessions s
    left join user_stitching u
        on s.user_pseudo_id = u.user_pseudo_id

)

select * from final

{% if is_incremental() %}
where session_date >= (select max(session_date) from {{ this }}) - interval 3 day
{% endif %}
