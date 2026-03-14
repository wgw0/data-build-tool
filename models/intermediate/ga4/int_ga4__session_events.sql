{{
  config(
    materialized='ephemeral'
  )
}}

{#
  Enriches each event with session-level context.
  Joins the flattened events to the sessionized intermediate table so
  downstream models can access both event-level detail and session-level
  attributes in a single scan.
#}

with events as (

    select * from {{ ref('stg_ga4__events') }}
    where ga_session_id is not null

),

sessions as (

    select * from {{ ref('int_ga4__sessions') }}

),

enriched as (

    select
        e.*,

        -- Session context
        s.session_key,
        s.session_start_at,
        s.session_end_at,
        s.session_duration_sec,
        s.is_engaged_session,
        s.is_first_session,
        s.landing_page,
        s.exit_page,
        s.pageview_count as session_pageview_count,
        s.event_count as session_event_count,

        -- Session traffic source (resolved)
        coalesce(e.event_source, s.session_source) as resolved_source,
        coalesce(e.event_medium, s.session_medium) as resolved_medium,
        coalesce(e.event_campaign, s.session_campaign) as resolved_campaign,

        -- Session revenue context
        s.session_revenue_usd,
        s.has_purchase as session_has_purchase

    from events e
    left join sessions s
        on e.user_pseudo_id = s.user_pseudo_id
        and e.ga_session_id = s.ga_session_id

)

select * from enriched
