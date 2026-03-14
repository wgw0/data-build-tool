{{
  config(
    materialized='table'
  )
}}

{#
  Traffic source dimension table.
  One row per unique source/medium/campaign combination observed across
  all sessions. Includes the default channel grouping classification.
#}

with sessions as (

    select * from {{ ref('int_ga4__sessions') }}

),

traffic_sources as (

    select
        coalesce(collected_session_source, session_source) as source,
        coalesce(collected_session_medium, session_medium) as medium,
        coalesce(collected_session_campaign, session_campaign) as campaign,
        session_term,
        session_content
    from sessions
    where coalesce(collected_session_source, session_source) is not null
       or coalesce(collected_session_medium, session_medium) is not null

),

distinct_sources as (

    select distinct
        coalesce(source, '(direct)') as source,
        coalesce(medium, '(none)') as medium,
        coalesce(campaign, '(not set)') as campaign
    from traffic_sources

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['source', 'medium', 'campaign']) }} as traffic_source_key,
        source,
        medium,
        campaign,
        {{ default_channel_grouping('source', 'medium', 'campaign') }} as default_channel_grouping
    from distinct_sources

)

select * from final
