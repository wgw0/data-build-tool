# GA4 BigQuery dbt Project

A production-ready dbt project that transforms the raw GA4 BigQuery export into clean, query-ready analytics tables. Flattens deeply nested schemas, builds sessionization, and delivers mart-layer fact and dimension tables for ecommerce analytics.

---

## Quick Start

### 1. Prerequisites

- [dbt-core](https://docs.getdbt.com/docs/core/installation) >= 1.7 with the `dbt-bigquery` adapter
- A Google Cloud project with GA4 BigQuery export enabled
- BigQuery credentials (OAuth or service account)

### 2. Clone & Configure

```bash
git clone https://github.com/wgw0/data-build-tool.git
cd data-build-tool
```

Copy the example profile and edit with your project details:

```bash
cp profiles.yml.example ~/.dbt/profiles.yml
# Edit ~/.dbt/profiles.yml with your GCP project, dataset, and auth method
```

### 3. Set Variables

Edit `dbt_project.yml` and update the `vars` section:

```yaml
vars:
  ga4_database: "your-gcp-project-id"       # Your GCP project
  ga4_schema: "analytics_123456789"          # Your GA4 property dataset
  ga4_start_date: "20240101"                 # How far back to process
  ga4_conversion_events:                     # Events that count as conversions
    - "purchase"
    - "sign_up"
    - "generate_lead"
    - "add_to_cart"
    - "begin_checkout"
```

### 4. Install & Run

```bash
dbt deps          # Install dbt_utils
dbt seed          # Load channel grouping reference data
dbt run           # Build all models
dbt test          # Run schema tests
dbt docs generate # Generate documentation
dbt docs serve    # Browse interactive docs
```

---

## Project Structure

```
models/
├── staging/ga4/              # Flatten raw GA4 nested schema
│   ├── stg_ga4__events.sql           # 50+ columns extracted from nested fields
│   ├── stg_ga4__event_params.sql     # Unnested event parameters (key-value)
│   ├── stg_ga4__user_properties.sql  # Unnested user properties
│   └── stg_ga4__items.sql            # Unnested ecommerce items
│
├── intermediate/ga4/         # Business logic layer
│   ├── int_ga4__sessions.sql         # Sessionization (the hard part)
│   ├── int_ga4__session_events.sql   # Events enriched with session context
│   └── int_ga4__user_stitching.sql   # user_pseudo_id → user_id mapping
│
└── marts/ga4/                # Analysis-ready tables
    ├── fct_ga4__sessions.sql         # Session-level fact table
    ├── fct_ga4__conversions.sql      # Conversion events fact table
    ├── fct_ga4__pageviews.sql        # Pageview fact with time-on-page
    ├── fct_ga4__ecommerce.sql        # Item-level ecommerce funnel
    ├── dim_ga4__users.sql            # User dimension with lifetime metrics
    ├── dim_ga4__traffic_sources.sql  # Source/medium/campaign dimension
    └── rpt_ga4__daily_overview.sql   # Executive daily KPI rollup

macros/
├── extract_event_param.sql   # Extract values from nested event_params
├── default_channel_grouping.sql  # GA4 default channel grouping logic
└── safe_timestamp.sql        # Convert microsecond timestamps

seeds/
└── channel_grouping_rules.csv  # Reference data for channel classification
```

---

## Layer Details

### Staging (`stg_ga4__*`)

**Materialized as:** Views

Flattens the raw GA4 BigQuery export. The `events_*` table contains deeply nested `RECORD` and `REPEATED` fields — these models extract the most commonly used fields into flat columns while preserving the original nested arrays for custom access.

Key transformations:
- `event_timestamp` (microseconds) → proper `TIMESTAMP`
- Common `event_params` pivoted into columns (page_location, source, medium, etc.)
- Ecommerce struct fields extracted
- Device, geo, and traffic source structs flattened

### Intermediate (`int_ga4__*`)

**Materialized as:** Ephemeral (no tables created)

Business logic that sits between raw data and final marts:

- **Sessions**: Groups events by `user_pseudo_id + ga_session_id`, computes duration, engagement, landing/exit pages, traffic source, and ecommerce metrics
- **Session Events**: Joins each event back to its session for enriched context
- **User Stitching**: Resolves `user_pseudo_id` → `user_id` using the most recent authenticated identity

### Marts (`fct_ga4__*`, `dim_ga4__*`, `rpt_ga4__*`)

**Materialized as:** Incremental tables (partitioned by date)

Clean, analysis-ready tables:

| Model | Grain | Description |
|-------|-------|-------------|
| `fct_ga4__sessions` | Session | Full session metrics with attribution |
| `fct_ga4__conversions` | Event | Conversion events with session context |
| `fct_ga4__pageviews` | Event | Pageviews with time-on-page |
| `fct_ga4__ecommerce` | Item × Event | Shopping funnel (browse → purchase) |
| `dim_ga4__users` | User | Lifetime metrics and segmentation |
| `dim_ga4__traffic_sources` | Source combo | Channel grouping dimension |
| `rpt_ga4__daily_overview` | Day | Executive KPI dashboard table |

---

## Macros

### `extract_event_param(event_params, param_key, value_type)`

Extracts a value from the nested `event_params` array:

```sql
{{ extract_event_param('event_params', 'page_location', 'string') }}
{{ extract_event_param('event_params', 'ga_session_id', 'int') }}
```

### `default_channel_grouping(source, medium, campaign)`

Implements GA4's default channel grouping rules (2026 version) including AI search engines (Perplexity, ChatGPT, Gemini) and newer social platforms (Bluesky, Mastodon, Threads):

```sql
{{ default_channel_grouping('source_col', 'medium_col', 'campaign_col') }}
```

### `safe_timestamp(microsecond_ts)`

Converts GA4 microsecond timestamps to BigQuery `TIMESTAMP`:

```sql
{{ safe_timestamp('event_timestamp') }}
-- Output: timestamp_micros(event_timestamp)
```

---

## Key Modeling Decisions

| Decision | Approach |
|----------|----------|
| **Sessionization** | `ga_session_id` + `ga_session_number` from event_params, grouped by `user_pseudo_id` |
| **Event param extraction** | Common params pivoted into columns; full key-value available in `stg_ga4__event_params` |
| **Timestamps** | `event_timestamp` (microseconds) → `TIMESTAMP` via `timestamp_micros()` |
| **Partitioning** | All mart tables partitioned by date for cost efficiency |
| **Incremental** | Large fact tables use incremental materialization with 3-day lookback |
| **Channel grouping** | Macro implements GA4's 2026 default rules including AI/LLM search |
| **User identity** | Coalesce `user_id` (authenticated) → `user_pseudo_id` (anonymous) |
| **Traffic source** | Prefer `collected_traffic_source` (event-level) over `traffic_source` (user-level) |

---

## Customization

### Adding Custom Event Parameters

To extract additional event parameters, add them to `stg_ga4__events.sql`:

```sql
{{ extract_event_param('event_params', 'your_custom_param', 'string') }} as your_custom_param,
```

### Adding Conversion Events

Update the `ga4_conversion_events` var in `dbt_project.yml`:

```yaml
vars:
  ga4_conversion_events:
    - "purchase"
    - "sign_up"
    - "your_custom_conversion"
```

### Changing Materialization

Override in `dbt_project.yml`:

```yaml
models:
  ga4_bigquery:
    marts:
      ga4:
        +materialized: incremental  # or table, view
```

---

## Testing

The project includes schema tests across all layers:

- **Not null**: Key identifiers and dates
- **Unique**: Surrogate keys and dimension keys
- **Accepted values**: Ecommerce event names, user segments
- **Referential integrity**: Cross-model relationships

Run all tests:

```bash
dbt test
```

---

## License

MIT
