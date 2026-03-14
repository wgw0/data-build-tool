# Looker Studio — Ready-to-Use Queries

These SQL queries are designed to be dropped directly into Looker Studio's custom query data source, connected to your BigQuery project.

**How to use in Looker Studio:**
1. Open [Looker Studio](https://lookerstudio.google.com)
2. Create a new report → Add data → BigQuery → Custom Query
3. Select your GCP project
4. Paste any query below (replace `your-project` and `dbt_dev` with your actual values)
5. Click "Add" → build your charts

> **Important:** Replace `your-project.dbt_dev` in every query with your actual GCP project ID and dbt dataset name.

---

## 1. Daily KPI Dashboard

Everything you need for an executive overview — one row per day.

```sql
-- Daily KPI Overview
-- Use with: Scorecard, Time Series, Table
SELECT
  report_date,
  total_users,
  new_users,
  returning_users,
  total_sessions,
  engaged_sessions,
  ROUND(engagement_rate * 100, 1) AS engagement_rate_pct,
  ROUND(bounce_rate * 100, 1) AS bounce_rate_pct,
  total_pageviews,
  ROUND(avg_pageviews_per_session, 1) AS avg_pages_per_session,
  ROUND(avg_session_duration_sec, 0) AS avg_session_duration_sec,
  total_conversions,
  ROUND(session_conversion_rate * 100, 2) AS session_conversion_rate_pct,
  ROUND(total_revenue_usd, 2) AS total_revenue_usd,
  total_purchases,
  ROUND(avg_order_value_usd, 2) AS avg_order_value_usd,
  ROUND(purchase_conversion_rate * 100, 2) AS purchase_conversion_rate_pct
FROM `your-project.dbt_dev.rpt_ga4__daily_overview`
ORDER BY report_date DESC
```

---

## 2. Traffic Source Performance

Which channels bring the most users, sessions, and revenue?

```sql
-- Traffic Source Performance (Last 30 Days)
-- Use with: Bar Chart, Pie Chart, Table
SELECT
  default_channel_grouping AS channel,
  session_source AS source,
  session_medium AS medium,
  COUNT(*) AS sessions,
  COUNT(DISTINCT unified_user_id) AS users,
  COUNTIF(is_engaged_session) AS engaged_sessions,
  ROUND(SAFE_DIVIDE(COUNTIF(is_engaged_session), COUNT(*)) * 100, 1) AS engagement_rate_pct,
  SUM(conversion_count) AS conversions,
  ROUND(SAFE_DIVIDE(COUNTIF(has_conversion), COUNT(*)) * 100, 2) AS conversion_rate_pct,
  ROUND(SUM(session_revenue_usd), 2) AS revenue_usd,
  SUM(purchase_count) AS purchases
FROM `your-project.dbt_dev.fct_ga4__sessions`
WHERE session_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY 1, 2, 3
ORDER BY sessions DESC
```

---

## 3. Channel Grouping Summary

High-level channel performance for quick reporting.

```sql
-- Channel Grouping Summary (Last 30 Days)
-- Use with: Donut Chart, Stacked Bar, Table
SELECT
  default_channel_grouping AS channel,
  COUNT(*) AS sessions,
  COUNT(DISTINCT unified_user_id) AS users,
  ROUND(SAFE_DIVIDE(COUNTIF(is_engaged_session), COUNT(*)) * 100, 1) AS engagement_rate_pct,
  ROUND(SUM(session_revenue_usd), 2) AS revenue_usd,
  SUM(purchase_count) AS purchases,
  ROUND(SAFE_DIVIDE(SUM(session_revenue_usd), COUNTIF(has_purchase)), 2) AS avg_order_value
FROM `your-project.dbt_dev.fct_ga4__sessions`
WHERE session_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY 1
ORDER BY sessions DESC
```

---

## 4. Top Landing Pages

Which pages do users enter the site through?

```sql
-- Top Landing Pages (Last 30 Days)
-- Use with: Table, Bar Chart
SELECT
  landing_page,
  landing_page_title,
  COUNT(*) AS sessions,
  COUNT(DISTINCT unified_user_id) AS users,
  ROUND(SAFE_DIVIDE(COUNTIF(is_engaged_session), COUNT(*)) * 100, 1) AS engagement_rate_pct,
  ROUND(AVG(session_duration_sec), 0) AS avg_session_duration_sec,
  SUM(conversion_count) AS conversions,
  ROUND(SUM(session_revenue_usd), 2) AS revenue_usd
FROM `your-project.dbt_dev.fct_ga4__sessions`
WHERE session_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
  AND landing_page IS NOT NULL
GROUP BY 1, 2
ORDER BY sessions DESC
LIMIT 50
```

---

## 5. Top Pages by Pageviews

Most viewed pages with engagement metrics.

```sql
-- Top Pages by Pageviews (Last 30 Days)
-- Use with: Table
SELECT
  page_location,
  page_title,
  COUNT(*) AS pageviews,
  COUNT(DISTINCT unified_user_id) AS unique_users,
  ROUND(AVG(time_on_page_sec), 1) AS avg_time_on_page_sec,
  ROUND(AVG(engagement_time_msec / 1000.0), 1) AS avg_engagement_time_sec
FROM `your-project.dbt_dev.fct_ga4__pageviews`
WHERE event_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY 1, 2
ORDER BY pageviews DESC
LIMIT 50
```

---

## 6. Ecommerce Funnel

How many users progress through each step of the shopping funnel?

```sql
-- Ecommerce Funnel (Last 30 Days)
-- Use with: Funnel Chart, Bar Chart
SELECT
  funnel_step_number,
  funnel_step_name,
  COUNT(*) AS total_events,
  COUNT(DISTINCT unified_user_id) AS unique_users
FROM `your-project.dbt_dev.fct_ga4__ecommerce`
WHERE event_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
  AND event_name != 'refund'
GROUP BY 1, 2
ORDER BY funnel_step_number ASC
```

---

## 7. Product Performance

Which products generate the most revenue?

```sql
-- Top Products by Revenue (Last 30 Days)
-- Use with: Table, Bar Chart
SELECT
  item_id,
  item_name,
  item_brand,
  item_category,
  COUNT(CASE WHEN event_name = 'view_item' THEN 1 END) AS product_views,
  COUNT(CASE WHEN event_name = 'add_to_cart' THEN 1 END) AS add_to_carts,
  COUNT(CASE WHEN event_name = 'purchase' THEN 1 END) AS purchases,
  SUM(CASE WHEN event_name = 'purchase' THEN item_quantity ELSE 0 END) AS units_sold,
  ROUND(SUM(CASE WHEN event_name = 'purchase' THEN item_revenue_usd ELSE 0 END), 2) AS revenue_usd,
  ROUND(SAFE_DIVIDE(
    COUNT(CASE WHEN event_name = 'purchase' THEN 1 END),
    COUNT(CASE WHEN event_name = 'view_item' THEN 1 END)
  ) * 100, 2) AS view_to_purchase_rate_pct
FROM `your-project.dbt_dev.fct_ga4__ecommerce`
WHERE event_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY 1, 2, 3, 4
ORDER BY revenue_usd DESC
LIMIT 50
```

---

## 8. User Segments

Breakdown of your user base by behavior segment.

```sql
-- User Segments
-- Use with: Pie Chart, Scorecard, Table
SELECT
  user_segment,
  COUNT(*) AS users,
  ROUND(AVG(lifetime_session_count), 1) AS avg_sessions,
  ROUND(AVG(lifetime_pageview_count), 1) AS avg_pageviews,
  ROUND(AVG(lifetime_revenue_usd), 2) AS avg_revenue_usd,
  ROUND(SUM(lifetime_revenue_usd), 2) AS total_revenue_usd,
  SUM(lifetime_purchase_count) AS total_purchases
FROM `your-project.dbt_dev.dim_ga4__users`
GROUP BY 1
ORDER BY users DESC
```

---

## 9. New vs Returning Users Over Time

Daily breakdown of new vs returning user sessions.

```sql
-- New vs Returning Users (Last 90 Days)
-- Use with: Stacked Area Chart, Time Series
SELECT
  session_date,
  COUNTIF(is_first_session) AS new_user_sessions,
  COUNTIF(NOT is_first_session) AS returning_user_sessions,
  COUNT(*) AS total_sessions,
  ROUND(SAFE_DIVIDE(COUNTIF(is_first_session), COUNT(*)) * 100, 1) AS new_user_pct
FROM `your-project.dbt_dev.fct_ga4__sessions`
WHERE session_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
GROUP BY 1
ORDER BY 1
```

---

## 10. Device & Geography Breakdown

Where are your users, and what devices do they use?

```sql
-- Device Category Breakdown (Last 30 Days)
-- Use with: Pie Chart, Table
SELECT
  device_category,
  COUNT(*) AS sessions,
  COUNT(DISTINCT unified_user_id) AS users,
  ROUND(SAFE_DIVIDE(COUNTIF(is_engaged_session), COUNT(*)) * 100, 1) AS engagement_rate_pct,
  ROUND(SUM(session_revenue_usd), 2) AS revenue_usd
FROM `your-project.dbt_dev.fct_ga4__sessions`
WHERE session_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY 1
ORDER BY sessions DESC
```

```sql
-- Top Countries (Last 30 Days)
-- Use with: Geo Map, Table
SELECT
  geo_country,
  COUNT(*) AS sessions,
  COUNT(DISTINCT unified_user_id) AS users,
  ROUND(SUM(session_revenue_usd), 2) AS revenue_usd,
  SUM(purchase_count) AS purchases
FROM `your-project.dbt_dev.fct_ga4__sessions`
WHERE session_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY 1
ORDER BY sessions DESC
LIMIT 30
```

---

## 11. Conversion Attribution

Which channels and campaigns drive the most conversions?

```sql
-- Conversion Attribution (Last 30 Days)
-- Use with: Table, Bar Chart
SELECT
  default_channel_grouping AS channel,
  source,
  medium,
  campaign,
  COUNT(*) AS conversions,
  COUNT(DISTINCT unified_user_id) AS converting_users,
  ROUND(SUM(ecommerce_purchase_revenue_usd), 2) AS revenue_usd
FROM `your-project.dbt_dev.fct_ga4__conversions`
WHERE event_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY 1, 2, 3, 4
ORDER BY conversions DESC
LIMIT 30
```

---

## 12. High-Value Customers

Your most valuable users by lifetime revenue.

```sql
-- Top 100 Customers by Lifetime Revenue
-- Use with: Table
SELECT
  unified_user_id,
  user_segment,
  first_seen_date,
  last_seen_date,
  days_since_first_seen,
  lifetime_session_count,
  lifetime_purchase_count,
  ROUND(lifetime_revenue_usd, 2) AS lifetime_revenue_usd,
  first_default_channel_grouping AS acquisition_channel,
  first_geo_country AS country
FROM `your-project.dbt_dev.dim_ga4__users`
WHERE lifetime_revenue_usd > 0
ORDER BY lifetime_revenue_usd DESC
LIMIT 100
```

---

## Tips for Looker Studio

1. **Date range controls**: Add a date range filter to your report, then use Looker Studio's built-in date parameters instead of the hardcoded `DATE_SUB` in these queries.

2. **Blending data**: You can use multiple queries as different data sources and blend them in a single chart.

3. **Caching**: Looker Studio caches BigQuery results. Set the cache to refresh every 12 hours to balance cost and freshness.

4. **Cost control**: These queries scan partitioned tables, so filtering by date keeps costs low. Avoid `SELECT *` on large tables.

---

*Last updated: March 2026*
