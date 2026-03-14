{{
  config(
    materialized='view'
  )
}}

with source as (

    select
        user_pseudo_id,
        user_id,
        event_name,
        event_timestamp,
        event_date,
        ecommerce,
        items,
        _table_suffix as table_suffix
    from {{ source('ga4', 'events') }}
    where _table_suffix >= '{{ var("ga4_start_date") }}'

),

flattened as (

    select
        user_pseudo_id,
        user_id,
        event_name,
        {{ safe_timestamp('event_timestamp') }} as event_timestamp,
        cast(parse_date('%Y%m%d', event_date) as date) as event_date,

        -- Item fields
        item.item_id,
        item.item_name,
        item.item_brand,
        item.item_variant,
        item.item_category,
        item.item_category2,
        item.item_category3,
        item.item_category4,
        item.item_category5,
        item.price_in_usd as item_price_usd,
        item.price as item_price,
        item.quantity as item_quantity,
        item.item_revenue_in_usd as item_revenue_usd,
        item.item_revenue,
        item.item_refund_in_usd as item_refund_usd,
        item.item_refund,
        item.coupon as item_coupon,
        item.affiliation as item_affiliation,
        item.location_id as item_location_id,
        item.item_list_id,
        item.item_list_name,
        item.item_list_index,
        item.promotion_id as item_promotion_id,
        item.promotion_name as item_promotion_name,
        item.creative_name as item_creative_name,
        item.creative_slot as item_creative_slot,

        -- Ecommerce context
        ecommerce.transaction_id as ecommerce_transaction_id,

        table_suffix as event_date_suffix

    from source,
    unnest(items) as item

)

select * from flattened
