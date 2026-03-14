{{
  config(
    materialized='view'
  )
}}

with source as (

    select
        *,
        _table_suffix as table_suffix
    from {{ source('ga4', 'events') }}
    where _table_suffix >= '{{ var("ga4_start_date") }}'

),

renamed as (

    select
        -- Event identifiers
        concat(
            cast(user_pseudo_id as string),
            cast(event_timestamp as string),
            event_name
        ) as event_surrogate_key,
        event_name,
        {{ safe_timestamp('event_timestamp') }} as event_timestamp,
        cast(
            parse_date('%Y%m%d', event_date)
            as date
        ) as event_date,
        event_bundle_sequence_id,
        event_server_timestamp_offset,

        -- Event params (common ones pivoted into columns)
        {{ extract_event_param('event_params', 'ga_session_id', 'int') }} as ga_session_id,
        {{ extract_event_param('event_params', 'ga_session_number', 'int') }} as ga_session_number,
        {{ extract_event_param('event_params', 'page_location', 'string') }} as page_location,
        {{ extract_event_param('event_params', 'page_title', 'string') }} as page_title,
        {{ extract_event_param('event_params', 'page_referrer', 'string') }} as page_referrer,
        {{ extract_event_param('event_params', 'source', 'string') }} as event_source,
        {{ extract_event_param('event_params', 'medium', 'string') }} as event_medium,
        {{ extract_event_param('event_params', 'campaign', 'string') }} as event_campaign,
        {{ extract_event_param('event_params', 'term', 'string') }} as event_term,
        {{ extract_event_param('event_params', 'content', 'string') }} as event_content,
        {{ extract_event_param('event_params', 'engagement_time_msec', 'int') }} as engagement_time_msec,
        {{ extract_event_param('event_params', 'engaged_session_event', 'int') }} as engaged_session_event,
        {{ extract_event_param('event_params', 'entrances', 'int') }} as entrances,
        {{ extract_event_param('event_params', 'session_engaged', 'string') }} as session_engaged,
        {{ extract_event_param('event_params', 'percent_scrolled', 'int') }} as percent_scrolled,
        {{ extract_event_param('event_params', 'outbound', 'string') }} as outbound_click,
        {{ extract_event_param('event_params', 'link_url', 'string') }} as link_url,
        {{ extract_event_param('event_params', 'link_text', 'string') }} as link_text,
        {{ extract_event_param('event_params', 'file_name', 'string') }} as file_name,
        {{ extract_event_param('event_params', 'search_term', 'string') }} as search_term,
        {{ extract_event_param('event_params', 'video_title', 'string') }} as video_title,
        {{ extract_event_param('event_params', 'video_url', 'string') }} as video_url,
        {{ extract_event_param('event_params', 'video_percent', 'int') }} as video_percent,
        {{ extract_event_param('event_params', 'visible', 'string') }} as visible,

        -- Ecommerce
        {{ extract_event_param('event_params', 'currency', 'string') }} as event_param_currency,
        {{ extract_event_param('event_params', 'value', 'float') }} as event_value,
        {{ extract_event_param('event_params', 'transaction_id', 'string') }} as transaction_id,
        {{ extract_event_param('event_params', 'shipping', 'float') }} as shipping_value,
        {{ extract_event_param('event_params', 'tax', 'float') }} as tax_value,
        {{ extract_event_param('event_params', 'coupon', 'string') }} as coupon,
        {{ extract_event_param('event_params', 'payment_type', 'string') }} as payment_type,

        -- Ecommerce struct
        ecommerce.total_item_quantity as ecommerce_total_item_quantity,
        ecommerce.purchase_revenue_in_usd as ecommerce_purchase_revenue_usd,
        ecommerce.purchase_revenue as ecommerce_purchase_revenue,
        ecommerce.refund_value_in_usd as ecommerce_refund_value_usd,
        ecommerce.refund_value as ecommerce_refund_value,
        ecommerce.shipping_value_in_usd as ecommerce_shipping_value_usd,
        ecommerce.shipping_value as ecommerce_shipping_value,
        ecommerce.tax_value_in_usd as ecommerce_tax_value_usd,
        ecommerce.tax_value as ecommerce_tax_value,
        ecommerce.unique_items as ecommerce_unique_items,
        ecommerce.transaction_id as ecommerce_transaction_id,

        -- User identifiers
        user_id,
        user_pseudo_id,

        -- User properties (nested — see stg_ga4__user_properties for flattened)
        user_properties,

        -- Privacy info
        privacy_info.analytics_storage as privacy_analytics_storage,
        privacy_info.ads_storage as privacy_ads_storage,
        privacy_info.uses_transient_token as privacy_uses_transient_token,

        -- Device info
        device.category as device_category,
        device.mobile_brand_name as device_mobile_brand,
        device.mobile_model_name as device_mobile_model,
        device.mobile_marketing_name as device_mobile_marketing_name,
        device.mobile_os_hardware_model as device_mobile_os_hardware_model,
        device.operating_system as device_os,
        device.operating_system_version as device_os_version,
        device.vendor_id as device_vendor_id,
        device.advertising_id as device_advertising_id,
        device.language as device_language,
        device.is_limited_ad_tracking as device_is_limited_ad_tracking,
        device.web_info.browser as device_browser,
        device.web_info.browser_version as device_browser_version,
        device.web_info.hostname as device_hostname,

        -- Geo info
        geo.continent as geo_continent,
        geo.sub_continent as geo_sub_continent,
        geo.country as geo_country,
        geo.region as geo_region,
        geo.city as geo_city,
        geo.metro as geo_metro,

        -- Traffic source (user-level attribution)
        traffic_source.name as traffic_source_name,
        traffic_source.medium as traffic_source_medium,
        traffic_source.source as traffic_source_source,

        -- Collected traffic source (event-level, GA4 2024+)
        collected_traffic_source.manual_campaign_id as collected_campaign_id,
        collected_traffic_source.manual_campaign_name as collected_campaign_name,
        collected_traffic_source.manual_source as collected_source,
        collected_traffic_source.manual_medium as collected_medium,
        collected_traffic_source.manual_term as collected_term,
        collected_traffic_source.manual_content as collected_content,
        collected_traffic_source.gclid as collected_gclid,
        collected_traffic_source.dclid as collected_dclid,
        collected_traffic_source.srsltid as collected_srsltid,

        -- Stream / platform
        stream_id,
        platform,

        -- Items array (nested — see stg_ga4__items for flattened)
        items,

        -- Event params array (nested — see stg_ga4__event_params for flattened)
        event_params,

        -- Misc
        user_first_touch_timestamp,
        {{ safe_timestamp('user_first_touch_timestamp') }} as user_first_touch_at,
        user_ltv.revenue as user_ltv_revenue,
        user_ltv.currency as user_ltv_currency,
        table_suffix as event_date_suffix,

        -- Is conversion flag
        event_name in unnest({{ var('ga4_conversion_events') }}) as is_conversion_event

    from source

)

select * from renamed
