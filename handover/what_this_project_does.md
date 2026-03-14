# What This Project Does — And Why It Matters

## The Short Version

This project takes the raw, messy data that Google Analytics 4 (GA4) dumps into BigQuery and transforms it into clean, simple tables that anyone on your team can query, chart, and build dashboards from.

**Before this project:** Your GA4 data in BigQuery looks like a tangled mess of nested arrays and cryptic field names. Even experienced analysts struggle to write basic queries against it.

**After this project:** You get clean tables like "one row per session" and "one row per user" that answer business questions directly.

---

## What Problem Does This Solve?

When you connect GA4 to BigQuery, Google dumps your analytics data into a format that's extremely difficult to work with:

- **Everything is nested.** Want the page URL? It's buried inside an array called `event_params` as a key-value pair. You need a subquery just to extract it.
- **There are no sessions.** GA4 records individual events (clicks, pageviews, purchases), but doesn't group them into sessions. You have to build that yourself.
- **There's no clean user table.** Users have both an anonymous ID and (sometimes) a logged-in ID. Connecting the two requires custom logic.
- **Timestamps are in microseconds.** Not seconds, not milliseconds — microseconds since 1970. Good luck reading that.
- **One giant table.** Everything — pageviews, purchases, video plays, scroll events — is crammed into a single table with 50+ columns.

Writing a simple query like *"How many sessions did we get from Google Ads last week?"* against the raw data requires 20+ lines of complex SQL with subqueries and unnesting.

**This project does all that hard work once**, so every future query is simple.

---

## What You Get

After running this project, seven clean tables appear in your BigQuery dataset:

### Fact Tables (What Happened)

| Table | What It Tells You | Example Question It Answers |
|---|---|---|
| **Sessions** | Everything about each visit to your site | "How many sessions came from email this month?" |
| **Conversions** | Every time a user completed a goal | "Which campaigns drove the most sign-ups?" |
| **Pageviews** | Every page that was viewed | "What's the average time spent on our pricing page?" |
| **Ecommerce** | Every step of the shopping journey | "Where do users drop off between cart and purchase?" |

### Dimension Tables (Who and Where)

| Table | What It Tells You | Example Question It Answers |
|---|---|---|
| **Users** | Lifetime profile of each user | "How many users have purchased more than once?" |
| **Traffic Sources** | Every source/medium/campaign combination | "What channels are we getting traffic from?" |

### Report Tables (Daily Summary)

| Table | What It Tells You | Example Question It Answers |
|---|---|---|
| **Daily Overview** | One row per day with all key metrics | "What were yesterday's total users, sessions, and revenue?" |

---

## How It Provides Value

### 1. Saves Analyst Time

Without this project, every analyst who touches your GA4 BigQuery data has to figure out the nested schema, write complex unnesting queries, and reinvent sessionization logic. That's hours per person, repeated across your team.

With this project, they write simple `SELECT` statements against clean tables.

### 2. Ensures Consistency

When five analysts each write their own session logic, you get five slightly different session counts. This project defines sessionization, channel grouping, and user identity once — everyone uses the same definitions.

### 3. Enables Self-Service Analytics

Non-technical team members can connect Looker Studio (or any BI tool) to these tables and build their own dashboards. No SQL expertise needed to drag and drop columns like "total_sessions" or "revenue_usd" into charts.

### 4. Supports Ecommerce Analysis

The ecommerce funnel table tracks every step from product browse to purchase. You can immediately see where users drop off and calculate conversion rates between each step — something that's extremely painful to build from raw GA4 data.

### 5. Runs Automatically

Set it to run once a day, and your analytics tables stay current with no manual work. GA4 exports new data daily, and this project picks it up and transforms it.

### 6. Costs Less to Query

All large tables are **partitioned by date**, which means BigQuery only scans the dates you're asking about. A query like "show me last week's sessions" scans 7 days of data instead of your entire history. This directly reduces your BigQuery bill.

---

## What It Actually Does (The Layers)

Think of it as an assembly line with three stages:

```
Raw GA4 Data    →    Stage 1: Clean    →    Stage 2: Combine    →    Stage 3: Deliver
(messy nested)       (flatten it)           (add business logic)     (ready to query)
```

### Stage 1: Staging — "Make it readable"
Takes the raw nested data and flattens it into normal columns. Extracts commonly-used values like page URL, session ID, traffic source, device type. Converts microsecond timestamps into readable dates.

### Stage 2: Intermediate — "Add business logic"
Groups events into sessions (using Google's session ID). Calculates session duration, landing pages, and exit pages. Maps anonymous users to their logged-in identities when available.

### Stage 3: Marts — "Answer business questions"
Produces the final tables your team queries. Adds channel grouping (Paid Search, Organic Social, etc.), user segments (New Visitor, Returning Visitor, Customer), and ecommerce funnel steps.

---

## What's Included in This Deliverable

| Item | Description |
|---|---|
| **14 SQL models** | The transformation logic across all three stages |
| **3 reusable macros** | Helper functions for common operations |
| **Schema tests** | Automated data quality checks (unique keys, not-null, valid values) |
| **Column documentation** | Descriptions for every column in every table |
| **Onboarding guide** | Step-by-step setup instructions |
| **Looker Studio queries** | 12 pre-built queries for common dashboards |
| **dbt Cloud guide** | Setup if you prefer a visual interface over command line |
| **Helper scripts** | One-command setup and daily run scripts |
| **Channel grouping rules** | Classifies traffic into channels matching GA4's 2026 rules |

---

## What You Need to Get Started

1. **GA4 linked to BigQuery** — your analytics data already flowing into a BigQuery dataset
2. **A Google Cloud project** — with BigQuery enabled
3. **15 minutes** — to configure three settings and run the setup command

See the [Client Onboarding Guide](client_onboarding_guide.md) for detailed setup steps.

---

## What It Doesn't Do

To set expectations clearly:

- **It doesn't replace GA4.** You still use the GA4 interface for real-time data, debugging, and audience creation
- **It doesn't create dashboards.** It creates the tables that power dashboards — you still need to build the charts in Looker Studio, Tableau, etc.
- **It doesn't handle consent/privacy.** It processes whatever data GA4 exports to BigQuery. Your consent management is handled separately in GA4
- **It doesn't cost money to run.** The dbt tool itself is free. You only pay for BigQuery compute (typically $1-10/day for most sites)

---

## Frequently Asked Questions

**How often should I run it?**
Once a day, after GA4 finishes its daily export (usually by 6 AM UTC). The included scheduler guide covers how to set this up.

**Will it get more expensive as my site grows?**
Slowly. BigQuery charges by data scanned, and since tables are partitioned by date, daily queries cost the same regardless of total history. A full rebuild (all historical data) costs more but is rare.

**Can I add custom metrics?**
Yes. The staging layer extracts the most common GA4 event parameters, but you can edit `stg_ga4__events.sql` to add any custom events or parameters your site tracks.

**What if my GA4 setup changes?**
The project reads from the raw GA4 export schema, which Google controls. If Google changes the schema (rare), the staging layer is the only part that needs updating.

**Can I use this with GA4 360?**
Yes. GA4 360 uses the same BigQuery export schema. The only difference is GA4 360 also exports intraday tables, which this project can be extended to support.

---

*Last updated: March 2026*
