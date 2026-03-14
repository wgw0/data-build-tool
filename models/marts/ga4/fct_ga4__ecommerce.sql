{{
  config(
    materialized='incremental',
    unique_key='ecommerce_event_key',
    partition_by={
      "field": "event_date",
      "data_type": "date",
      "granularity": "day"
    },
    cluster_by=['event_name', 'item_id']
  )
}}

{#
  Ecommerce item-level fact table.
  One row per item per ecommerce event. Covers the full shopping funnel:
  view_item_list, view_item, select_item, add_to_cart, remove_from_cart,
  view_cart, begin_checkout, add_shipping_info, add_payment_info, purchase, refund.
#}

with items as (

    select * from {{ ref('stg_ga4__items') }}
    where event_name in (
        'view_item_list',
        'view_item',
        'select_item',
        'add_to_cart',
        'remove_from_cart',
        'view_cart',
        'begin_checkout',
        'add_shipping_info',
        'add_payment_info',
        'purchase',
        'refund'
    )

),

user_stitching as (

    select * from {{ ref('int_ga4__user_stitching') }}

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'i.user_pseudo_id',
            'i.event_timestamp',
            'i.event_name',
            'i.item_id'
        ]) }} as ecommerce_event_key,

        i.event_name,
        i.event_timestamp,
        i.event_date,
        i.user_pseudo_id,
        coalesce(u.stitched_user_id, i.user_id) as user_id,
        coalesce(u.stitched_user_id, i.user_pseudo_id) as unified_user_id,

        -- Item details
        i.item_id,
        i.item_name,
        i.item_brand,
        i.item_variant,
        i.item_category,
        i.item_category2,
        i.item_category3,
        i.item_category4,
        i.item_category5,
        i.item_price_usd,
        i.item_price,
        i.item_quantity,
        i.item_revenue_usd,
        i.item_revenue,
        i.item_refund_usd,
        i.item_refund,
        i.item_coupon,
        i.item_affiliation,
        i.item_location_id,
        i.item_list_id,
        i.item_list_name,
        i.item_list_index,
        i.item_promotion_id,
        i.item_promotion_name,
        i.item_creative_name,
        i.item_creative_slot,

        -- Transaction context
        i.ecommerce_transaction_id,

        -- Funnel stage
        case i.event_name
            when 'view_item_list' then 1
            when 'view_item' then 2
            when 'select_item' then 3
            when 'add_to_cart' then 4
            when 'remove_from_cart' then 4
            when 'view_cart' then 5
            when 'begin_checkout' then 6
            when 'add_shipping_info' then 7
            when 'add_payment_info' then 8
            when 'purchase' then 9
            when 'refund' then 10
        end as funnel_step_number,

        case i.event_name
            when 'view_item_list' then 'Browse'
            when 'view_item' then 'View Product'
            when 'select_item' then 'Select Product'
            when 'add_to_cart' then 'Add to Cart'
            when 'remove_from_cart' then 'Remove from Cart'
            when 'view_cart' then 'View Cart'
            when 'begin_checkout' then 'Begin Checkout'
            when 'add_shipping_info' then 'Add Shipping'
            when 'add_payment_info' then 'Add Payment'
            when 'purchase' then 'Purchase'
            when 'refund' then 'Refund'
        end as funnel_step_name

    from items i
    left join user_stitching u
        on i.user_pseudo_id = u.user_pseudo_id

)

select * from final

{% if is_incremental() %}
where event_date >= (select max(event_date) from {{ this }}) - interval 3 day
{% endif %}
