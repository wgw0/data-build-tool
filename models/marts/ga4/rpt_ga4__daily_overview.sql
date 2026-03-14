{{
  config(
    materialized='incremental',
    unique_key='report_date',
    partition_by={
      "field": "report_date",
      "data_type": "date",
      "granularity": "day"
    }
  )
}}

{#
  Daily KPI rollup report.
  One row per day with key GA4 metrics: users, sessions, pageviews,
  engagement, conversions, and revenue.
#}

with sessions as (

    select * from {{ ref('fct_ga4__sessions') }}

),

daily as (

    select
        session_date as report_date,

        -- Users
        count(distinct unified_user_id) as total_users,
        count(distinct case when is_first_session then unified_user_id end) as new_users,
        count(distinct unified_user_id)
            - count(distinct case when is_first_session then unified_user_id end) as returning_users,

        -- Sessions
        count(*) as total_sessions,
        countif(is_engaged_session) as engaged_sessions,
        safe_divide(countif(is_engaged_session), count(*)) as engagement_rate,
        safe_divide(
            count(*) - countif(is_engaged_session),
            count(*)
        ) as bounce_rate,

        -- Pageviews
        sum(pageview_count) as total_pageviews,
        safe_divide(sum(pageview_count), count(*)) as avg_pageviews_per_session,

        -- Engagement
        avg(session_duration_sec) as avg_session_duration_sec,
        avg(total_engagement_time_sec) as avg_engagement_time_sec,
        sum(event_count) as total_events,

        -- Conversions
        sum(conversion_count) as total_conversions,
        safe_divide(
            count(distinct case when has_conversion then unified_user_id end),
            count(distinct unified_user_id)
        ) as user_conversion_rate,
        safe_divide(
            countif(has_conversion),
            count(*)
        ) as session_conversion_rate,

        -- Ecommerce
        sum(session_revenue_usd) as total_revenue_usd,
        sum(purchase_count) as total_purchases,
        countif(has_purchase) as purchasing_sessions,
        safe_divide(sum(session_revenue_usd), count(*)) as revenue_per_session,
        safe_divide(sum(session_revenue_usd), sum(purchase_count)) as avg_order_value_usd,
        safe_divide(
            countif(has_purchase),
            count(*)
        ) as purchase_conversion_rate,

        -- Ecommerce funnel
        sum(view_item_count) as total_view_item,
        sum(add_to_cart_count) as total_add_to_cart,
        sum(begin_checkout_count) as total_begin_checkout,

        -- Channel mix
        count(distinct default_channel_grouping) as channel_count

    from sessions
    group by 1

)

select * from daily

{% if is_incremental() %}
where report_date >= (select max(report_date) from {{ this }}) - interval 3 day
{% endif %}
