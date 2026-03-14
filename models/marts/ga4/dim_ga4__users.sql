{{
  config(
    materialized='table',
    cluster_by=['unified_user_id']
  )
}}

{#
  User dimension table.
  One row per user (unified via user stitching). Contains first-touch
  attribution, lifetime engagement metrics, and user properties.
#}

with events as (

    select * from {{ ref('stg_ga4__events') }}

),

user_stitching as (

    select * from {{ ref('int_ga4__user_stitching') }}

),

user_agg as (

    select
        e.user_pseudo_id,
        coalesce(u.stitched_user_id, e.user_pseudo_id) as unified_user_id,
        max(e.user_id) as user_id,

        -- First and last seen
        min(e.event_timestamp) as first_seen_at,
        max(e.event_timestamp) as last_seen_at,
        min(e.event_date) as first_seen_date,
        max(e.event_date) as last_seen_date,
        min(e.user_first_touch_at) as user_first_touch_at,

        -- Lifetime engagement
        count(*) as lifetime_event_count,
        count(distinct e.ga_session_id) as lifetime_session_count,
        countif(e.event_name = 'page_view') as lifetime_pageview_count,
        sum(coalesce(e.engagement_time_msec, 0)) as lifetime_engagement_time_msec,
        round(sum(coalesce(e.engagement_time_msec, 0)) / 1000.0, 2) as lifetime_engagement_time_sec,

        -- Lifetime conversions & revenue
        countif(e.is_conversion_event) as lifetime_conversion_count,
        countif(e.event_name = 'purchase') as lifetime_purchase_count,
        sum(coalesce(e.ecommerce_purchase_revenue_usd, 0)) as lifetime_revenue_usd,
        max(e.user_ltv_revenue) as user_ltv_revenue,
        max(e.user_ltv_currency) as user_ltv_currency,

        -- First-touch attribution
        array_agg(e.traffic_source_source ignore nulls order by e.event_timestamp asc limit 1)[safe_offset(0)] as first_source,
        array_agg(e.traffic_source_medium ignore nulls order by e.event_timestamp asc limit 1)[safe_offset(0)] as first_medium,
        array_agg(e.traffic_source_name ignore nulls order by e.event_timestamp asc limit 1)[safe_offset(0)] as first_campaign,

        -- Device & geo (from first event)
        array_agg(e.device_category order by e.event_timestamp asc limit 1)[safe_offset(0)] as first_device_category,
        array_agg(e.device_os order by e.event_timestamp asc limit 1)[safe_offset(0)] as first_device_os,
        array_agg(e.device_browser order by e.event_timestamp asc limit 1)[safe_offset(0)] as first_device_browser,
        array_agg(e.geo_country order by e.event_timestamp asc limit 1)[safe_offset(0)] as first_geo_country,
        array_agg(e.geo_region order by e.event_timestamp asc limit 1)[safe_offset(0)] as first_geo_region,
        array_agg(e.geo_city order by e.event_timestamp asc limit 1)[safe_offset(0)] as first_geo_city,
        array_agg(e.platform order by e.event_timestamp asc limit 1)[safe_offset(0)] as first_platform,

        -- Latest device & geo
        array_agg(e.device_category order by e.event_timestamp desc limit 1)[safe_offset(0)] as last_device_category,
        array_agg(e.device_os order by e.event_timestamp desc limit 1)[safe_offset(0)] as last_device_os,
        array_agg(e.geo_country order by e.event_timestamp desc limit 1)[safe_offset(0)] as last_geo_country

    from events e
    left join user_stitching u
        on e.user_pseudo_id = u.user_pseudo_id
    group by 1, 2

),

final as (

    select
        *,
        {{ default_channel_grouping('first_source', 'first_medium', 'first_campaign') }} as first_default_channel_grouping,
        date_diff(last_seen_date, first_seen_date, day) as days_since_first_seen,
        case
            when lifetime_purchase_count > 0 then 'Customer'
            when lifetime_conversion_count > 0 then 'Converter'
            when lifetime_session_count > 1 then 'Returning Visitor'
            else 'New Visitor'
        end as user_segment

    from user_agg

)

select * from final
