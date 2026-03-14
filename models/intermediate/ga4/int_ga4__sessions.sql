{{
  config(
    materialized='ephemeral'
  )
}}

{#
  Sessionization logic for GA4 BigQuery data.
  
  Sessions are defined by the ga_session_id param combined with user_pseudo_id.
  This model aggregates event-level data to session-level grain.
#}

with events as (

    select * from {{ ref('stg_ga4__events') }}
    where ga_session_id is not null

),

session_aggregates as (

    select
        -- Session key
        {{ dbt_utils.generate_surrogate_key(['user_pseudo_id', 'ga_session_id']) }} as session_key,
        user_pseudo_id,
        ga_session_id,
        min(ga_session_number) as ga_session_number,
        coalesce(max(user_id), null) as user_id,

        -- Timestamps
        min(event_timestamp) as session_start_at,
        max(event_timestamp) as session_end_at,
        min(event_date) as session_date,

        -- Engagement
        sum(coalesce(engagement_time_msec, 0)) as total_engagement_time_msec,
        round(sum(coalesce(engagement_time_msec, 0)) / 1000.0, 2) as total_engagement_time_sec,
        max(case when session_engaged = '1' then true else false end) as is_engaged_session,
        countif(event_name = 'page_view') as pageview_count,
        count(distinct event_name) as distinct_event_count,
        count(*) as event_count,

        -- Landing / exit pages
        array_agg(page_location order by event_timestamp asc limit 1)[safe_offset(0)] as landing_page,
        array_agg(page_title order by event_timestamp asc limit 1)[safe_offset(0)] as landing_page_title,
        array_agg(page_location order by event_timestamp desc limit 1)[safe_offset(0)] as exit_page,

        -- Session traffic source (first non-null event-level source in session)
        array_agg(event_source ignore nulls order by event_timestamp asc limit 1)[safe_offset(0)] as session_source,
        array_agg(event_medium ignore nulls order by event_timestamp asc limit 1)[safe_offset(0)] as session_medium,
        array_agg(event_campaign ignore nulls order by event_timestamp asc limit 1)[safe_offset(0)] as session_campaign,
        array_agg(event_term ignore nulls order by event_timestamp asc limit 1)[safe_offset(0)] as session_term,
        array_agg(event_content ignore nulls order by event_timestamp asc limit 1)[safe_offset(0)] as session_content,

        -- Collected traffic source (GA4 2024+)
        array_agg(collected_source ignore nulls order by event_timestamp asc limit 1)[safe_offset(0)] as collected_session_source,
        array_agg(collected_medium ignore nulls order by event_timestamp asc limit 1)[safe_offset(0)] as collected_session_medium,
        array_agg(collected_campaign_name ignore nulls order by event_timestamp asc limit 1)[safe_offset(0)] as collected_session_campaign,
        array_agg(collected_gclid ignore nulls order by event_timestamp asc limit 1)[safe_offset(0)] as collected_session_gclid,

        -- User-level traffic source (first-touch)
        array_agg(traffic_source_source ignore nulls order by event_timestamp asc limit 1)[safe_offset(0)] as user_traffic_source,
        array_agg(traffic_source_medium ignore nulls order by event_timestamp asc limit 1)[safe_offset(0)] as user_traffic_medium,
        array_agg(traffic_source_name ignore nulls order by event_timestamp asc limit 1)[safe_offset(0)] as user_traffic_campaign,

        -- Device & geo (take from first event in session)
        array_agg(device_category order by event_timestamp asc limit 1)[safe_offset(0)] as device_category,
        array_agg(device_os order by event_timestamp asc limit 1)[safe_offset(0)] as device_os,
        array_agg(device_browser order by event_timestamp asc limit 1)[safe_offset(0)] as device_browser,
        array_agg(device_language order by event_timestamp asc limit 1)[safe_offset(0)] as device_language,
        array_agg(geo_continent order by event_timestamp asc limit 1)[safe_offset(0)] as geo_continent,
        array_agg(geo_country order by event_timestamp asc limit 1)[safe_offset(0)] as geo_country,
        array_agg(geo_region order by event_timestamp asc limit 1)[safe_offset(0)] as geo_region,
        array_agg(geo_city order by event_timestamp asc limit 1)[safe_offset(0)] as geo_city,
        array_agg(platform order by event_timestamp asc limit 1)[safe_offset(0)] as platform,

        -- Conversions
        countif(is_conversion_event) as conversion_count,
        max(is_conversion_event) as has_conversion,

        -- Ecommerce
        sum(coalesce(ecommerce_purchase_revenue_usd, 0)) as session_revenue_usd,
        countif(event_name = 'purchase') as purchase_count,
        countif(event_name = 'add_to_cart') as add_to_cart_count,
        countif(event_name = 'begin_checkout') as begin_checkout_count,
        countif(event_name = 'view_item') as view_item_count,
        countif(event_name = 'view_item_list') as view_item_list_count

    from events
    group by 1, 2, 3

)

select
    *,
    timestamp_diff(session_end_at, session_start_at, second) as session_duration_sec,
    case when ga_session_number = 1 then true else false end as is_first_session,
    case when purchase_count > 0 then true else false end as has_purchase
from session_aggregates
