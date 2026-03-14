{#
  default_channel_grouping(source, medium, campaign)

  Implements GA4's default channel grouping logic (2026 rules).
  Returns a channel group string based on source, medium, and campaign values.

  Usage:
    {{ default_channel_grouping('traffic_source_source', 'traffic_source_medium', 'traffic_source_campaign') }}
#}

{% macro default_channel_grouping(source, medium, campaign) %}
  case
    -- Direct
    when ({{ source }} is null or {{ source }} = '(direct)')
      and ({{ medium }} is null or {{ medium }} in ('(not set)', '(none)'))
      then 'Direct'

    -- Cross-network
    when {{ campaign }} like '%cross-network%'
      then 'Cross-network'

    -- Paid Shopping
    when (regexp_contains({{ source }}, r'alibaba|amazon|google shopping|shopify|etsy|ebay|stripe|walmart')
      or regexp_contains({{ campaign }}, r'^(.*(([^a-df-z]|^)shop|shopping).*)$'))
      and regexp_contains({{ medium }}, r'^(.*cp.*|ppc|retargeting|paid.*)$')
      then 'Paid Shopping'

    -- Paid Search
    when regexp_contains({{ source }}, r'baidu|bing|duckduckgo|ecosia|google|yahoo|yandex|ask|naver|brave|perplexity|chatgpt|gemini')
      and regexp_contains({{ medium }}, r'^(.*cp.*|ppc|retargeting|paid.*)$')
      then 'Paid Search'

    -- Paid Social
    when regexp_contains({{ source }}, r'badoo|facebook|fb|instagram|linkedin|pinterest|reddit|snapchat|tiktok|threads|twitter|x\.com|whatsapp|youtube|bluesky|mastodon')
      and regexp_contains({{ medium }}, r'^(.*cp.*|ppc|retargeting|paid.*)$')
      then 'Paid Social'

    -- Paid Video
    when regexp_contains({{ source }}, r'dailymotion|disneyplus|netflix|youtube|vimeo|twitch|hulu|roku')
      and regexp_contains({{ medium }}, r'^(.*cp.*|ppc|retargeting|paid.*)$')
      then 'Paid Video'

    -- Display
    when {{ medium }} in ('display', 'banner', 'expandable', 'interstitial', 'cpm')
      then 'Display'

    -- Paid Other
    when regexp_contains({{ medium }}, r'^(.*cp.*|ppc|retargeting|paid.*)$')
      then 'Paid Other'

    -- Organic Shopping
    when regexp_contains({{ source }}, r'alibaba|amazon|google shopping|shopify|etsy|ebay|stripe|walmart')
      or regexp_contains({{ campaign }}, r'^(.*(([^a-df-z]|^)shop|shopping).*)$')
      then 'Organic Shopping'

    -- Organic Social
    when regexp_contains({{ source }}, r'badoo|facebook|fb|instagram|linkedin|pinterest|reddit|snapchat|tiktok|threads|twitter|x\.com|whatsapp|youtube|bluesky|mastodon')
      or {{ medium }} in ('social', 'social-network', 'social-media', 'sm', 'social network', 'social media')
      then 'Organic Social'

    -- Organic Video
    when regexp_contains({{ source }}, r'dailymotion|disneyplus|netflix|youtube|vimeo|twitch|hulu|roku')
      or regexp_contains({{ medium }}, r'^(.*video.*)$')
      then 'Organic Video'

    -- Organic Search
    when regexp_contains({{ source }}, r'baidu|bing|duckduckgo|ecosia|google|yahoo|yandex|ask|naver|brave|perplexity|chatgpt|gemini')
      or {{ medium }} = 'organic'
      then 'Organic Search'

    -- Email
    when regexp_contains({{ source }}, r'email|e-mail|e_mail|e mail')
      or regexp_contains({{ medium }}, r'email|e-mail|e_mail|e mail')
      then 'Email'

    -- Affiliates
    when {{ medium }} = 'affiliate'
      then 'Affiliates'

    -- Referral
    when {{ medium }} = 'referral'
      then 'Referral'

    -- SMS
    when regexp_contains({{ source }}, r'sms|text')
      or regexp_contains({{ medium }}, r'sms|text')
      then 'SMS'

    -- Push Notifications
    when regexp_contains({{ medium }}, r'push$|mobile|notification')
      or {{ source }} = 'firebase'
      then 'Push Notifications'

    -- Audio
    when {{ medium }} = 'audio'
      then 'Audio'

    else 'Unassigned'
  end
{% endmacro %}
