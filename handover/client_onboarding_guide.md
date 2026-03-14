# Client Onboarding Guide

**Welcome!** This guide walks you through setting up your GA4 analytics pipeline — step by step, no coding experience required.

By the end you'll have clean, ready-to-query analytics tables in your BigQuery project that power dashboards, reports, and ad-hoc analysis.

---

## What You'll Need Before Starting

| Requirement | How to Check |
|---|---|
| **Google Cloud Project** | Go to [console.cloud.google.com](https://console.cloud.google.com) — you should see your project name in the top bar |
| **GA4 linked to BigQuery** | In GA4: Admin → Product Links → BigQuery Links (should show "Linked") |
| **BigQuery API enabled** | In GCP Console: APIs & Services → search "BigQuery API" → should say "Enabled" |
| **Your GA4 dataset name** | In BigQuery Console: look for a dataset like `analytics_123456789` — note this down |

> **Don't have GA4 linked to BigQuery yet?**
> Go to GA4 Admin → Product Links → BigQuery Links → Link. Select your GCP project, choose "Daily" export, and enable "Streaming" if you want real-time data. It takes 24-48 hours for the first data to appear.

---

## Step 1: Install the Tools

You need two things installed on your computer: **Python** and **dbt**.

### Option A: If You've Never Used Python (Recommended)

1. Download Python from [python.org/downloads](https://python.org/downloads)
   - On the installer, **check the box** that says "Add Python to PATH"
   - Click "Install Now"

2. Open a terminal:
   - **Windows**: Search for "PowerShell" in the Start menu
   - **Mac**: Open "Terminal" from Applications → Utilities

3. Run this command to install dbt:

```bash
pip install dbt-bigquery
```

4. Verify it worked:

```bash
dbt --version
```

You should see version numbers printed. If you get an error, try `pip3 install dbt-bigquery` instead.

### Option B: If You Already Have Python

```bash
pip install dbt-bigquery
```

---

## Step 2: Download This Project

### Option A: Using Git (if installed)

```bash
git clone https://github.com/wgw0/data-build-tool.git
cd data-build-tool
```

### Option B: Manual Download

1. Go to the repository page on GitHub
2. Click the green **Code** button → **Download ZIP**
3. Unzip the folder somewhere you can find it (e.g., your Desktop)
4. Open your terminal and navigate to the folder:

```bash
cd ~/Desktop/data-build-tool    # Mac
cd C:\Users\YourName\Desktop\data-build-tool   # Windows
```

---

## Step 3: Set Up Your BigQuery Connection

This tells dbt how to connect to your BigQuery project.

1. Copy the example profile:

```bash
# Mac/Linux
cp profiles.yml.example ~/.dbt/profiles.yml

# Windows (PowerShell)
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.dbt"
Copy-Item profiles.yml.example "$env:USERPROFILE\.dbt\profiles.yml"
```

2. Open the file `~/.dbt/profiles.yml` in any text editor (Notepad, VS Code, etc.)

3. Update these fields:

```yaml
ga4_bigquery:
  target: dev
  outputs:
    dev:
      type: bigquery
      method: oauth                    # ← Keep this for personal use
      project: "your-gcp-project-id"   # ← Replace with your GCP project ID
      dataset: "dbt_dev"               # ← This is where dbt creates tables
      threads: 4
      timeout_seconds: 300
      location: US                     # ← Match your BigQuery dataset location
```

> **Where do I find my GCP Project ID?**
> Go to [console.cloud.google.com](https://console.cloud.google.com) → click the project dropdown at the top → your Project ID is in the ID column (it looks like `my-company-12345`).

4. Authenticate with Google Cloud:

```bash
gcloud auth application-default login
```

This opens a browser window — sign in with your Google account that has BigQuery access.

> **Don't have gcloud installed?** Download it from [cloud.google.com/sdk/docs/install](https://cloud.google.com/sdk/docs/install)

---

## Step 4: Configure Your GA4 Settings

Open `dbt_project.yml` in a text editor and update the `vars` section at the bottom:

```yaml
vars:
  ga4_database: "my-company-12345"         # ← Your GCP Project ID
  ga4_schema: "analytics_123456789"        # ← Your GA4 BigQuery dataset name
  ga4_start_date: "20240101"               # ← Earliest date to process (YYYYMMDD)
  ga4_conversion_events:                   # ← Which events count as conversions
    - "purchase"
    - "sign_up"
    - "generate_lead"
    - "add_to_cart"
    - "begin_checkout"
```

> **Where do I find my GA4 dataset name?**
> In the [BigQuery Console](https://console.cloud.google.com/bigquery), look at the left sidebar. Under your project, you'll see a dataset named something like `analytics_301234567`. That's the one.

> **What should ga4_start_date be?**
> This controls how far back in history dbt processes. A good starting point is 90 days ago. Going back further processes more data (takes longer, costs more on first run). You can always change this later.

---

## Step 5: Run the Pipeline

### Option A: Using the Helper Script (Easiest)

```bash
# Mac/Linux
./handover/run.sh setup

# Windows (PowerShell — run from the project folder)
.\handover\run.ps1 setup
```

### Option B: Run Commands Manually

```bash
dbt deps          # Download required packages
dbt seed          # Load reference data
dbt run           # Build all analytics tables
dbt test          # Verify data quality
```

**What to expect:**
- `dbt deps` — takes a few seconds
- `dbt seed` — takes a few seconds
- `dbt run` — takes 2-15 minutes depending on data volume
- `dbt test` — takes 1-5 minutes

You'll see green "OK" or "PASS" messages for each model. If anything fails, the error message will tell you what went wrong.

---

## Step 6: Verify Your Tables

1. Go to [BigQuery Console](https://console.cloud.google.com/bigquery)
2. In the left sidebar, find the `dbt_dev` dataset (or whatever you set as `dataset` in Step 3)
3. You should see these tables:

| Table | What It Contains |
|---|---|
| `fct_ga4__sessions` | One row per website session — traffic source, engagement, revenue |
| `fct_ga4__conversions` | Conversion events (purchases, sign-ups, etc.) |
| `fct_ga4__pageviews` | Every page view with time-on-page |
| `fct_ga4__ecommerce` | Shopping funnel — view → cart → checkout → purchase |
| `dim_ga4__users` | One row per user with lifetime metrics |
| `dim_ga4__traffic_sources` | Unique source/medium/campaign combinations |
| `rpt_ga4__daily_overview` | One row per day with all KPIs |

4. Try a quick query to confirm data is there:

```sql
SELECT
  report_date,
  total_users,
  total_sessions,
  total_revenue_usd
FROM `your-project.dbt_dev.rpt_ga4__daily_overview`
ORDER BY report_date DESC
LIMIT 10
```

---

## Step 7: Connect Your Dashboards

Now that the tables exist in BigQuery, you can connect any BI tool:

- **Looker Studio** — See [Example Queries](looker_studio_queries.md) for ready-to-use SQL
- **Tableau** — Connect to BigQuery → select the `dbt_dev` dataset
- **Power BI** — Get Data → Google BigQuery → select your tables
- **Looker** — Add BigQuery connection → point at the mart tables

---

## Step 8: Schedule Daily Runs

GA4 exports a new table to BigQuery every day. To keep your analytics tables current, you need to run `dbt run` daily.

### Option A: dbt Cloud (Recommended for Teams)

See the [dbt Cloud Setup Guide](dbt_cloud_setup.md) — gives you a web UI, scheduling, alerting, and team collaboration with no command line needed.

### Option B: Simple Cron Job (Mac/Linux)

```bash
# Run dbt at 6 AM every day
crontab -e
# Add this line:
0 6 * * * cd /path/to/data-build-tool && dbt run
```

### Option C: Google Cloud Scheduler + Cloud Build

For production setups that run entirely in GCP. Contact your engineering team for setup.

---

## Troubleshooting

### "Could not find profile named 'ga4_bigquery'"
Your `profiles.yml` file isn't in the right place. It should be at `~/.dbt/profiles.yml`. Run Step 3 again.

### "Not found: Dataset analytics_XXXXXXXXX"
The `ga4_schema` value in `dbt_project.yml` doesn't match your actual GA4 dataset name. Check BigQuery Console for the correct name.

### "Access Denied: BigQuery"
Your Google account doesn't have BigQuery permissions. Ask your GCP admin to grant you the **BigQuery Data Editor** and **BigQuery Job User** roles.

### "No tables found matching events_*"
GA4 hasn't exported any data to BigQuery yet. After linking GA4 to BigQuery, it takes 24-48 hours for the first export. Also check that `ga4_start_date` isn't set to a date before your BigQuery export started.

### Models are running but tables are empty
Check that `ga4_start_date` isn't set to a future date or after your most recent data. Try setting it to a date you know has data.

---

## Getting Help

- **dbt documentation**: Run `dbt docs generate && dbt docs serve` to browse interactive model documentation in your browser
- **BigQuery Console**: Test queries directly at [console.cloud.google.com/bigquery](https://console.cloud.google.com/bigquery)
- **dbt community**: [community.getdbt.com](https://community.getdbt.com)

---

*Last updated: March 2026*
