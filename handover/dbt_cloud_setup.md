# dbt Cloud Setup Guide

**dbt Cloud** is the managed, web-based version of dbt. It gives you a visual interface for running models, scheduling jobs, viewing lineage graphs, and collaborating with your team — no command line required.

This guide walks you through setting up this GA4 project in dbt Cloud.

---

## Why dbt Cloud?

| Feature | Command Line (dbt Core) | dbt Cloud |
|---|---|---|
| Run models | Terminal commands | Click a button |
| Schedule daily runs | Set up cron/Cloud Scheduler yourself | Built-in scheduler |
| View documentation | `dbt docs serve` locally | Always-on hosted docs |
| See model lineage | Local browser | Interactive DAG in the UI |
| Error alerts | Build your own | Email/Slack notifications |
| Team collaboration | Git only | IDE + Git + permissions |
| Cost | Free | Free tier available (1 developer seat) |

---

## Step 1: Create a dbt Cloud Account

1. Go to [cloud.getdbt.com/signup](https://cloud.getdbt.com/signup)
2. Sign up with your email or Google account
3. You'll land on the project setup wizard

---

## Step 2: Connect Your Repository

1. In the setup wizard, select **GitHub** (or GitLab/Bitbucket if applicable)
2. Authorize dbt Cloud to access your GitHub account
3. Select the repository: `wgw0/data-build-tool`
4. If prompted for a subdirectory, leave it blank (the `dbt_project.yml` is at the root)

---

## Step 3: Connect BigQuery

1. Select **BigQuery** as your data warehouse
2. Upload your **service account JSON key file**:

   > **How to create a service account:**
   > 1. Go to [GCP Console → IAM → Service Accounts](https://console.cloud.google.com/iam-admin/serviceaccounts)
   > 2. Click **Create Service Account**
   > 3. Name it `dbt-cloud` (or similar)
   > 4. Grant these roles:
   >    - **BigQuery Data Editor** — to create/modify tables
   >    - **BigQuery Job User** — to run queries
   > 5. Click **Done**, then click into the service account
   > 6. Go to **Keys** tab → **Add Key** → **Create new key** → **JSON**
   > 7. A `.json` file downloads — this is what you upload to dbt Cloud

3. After uploading, dbt Cloud auto-fills most settings. Verify:
   - **Project**: Your GCP project ID
   - **Dataset**: `dbt_prod` (or your preferred output dataset)
   - **Location**: Match your BigQuery dataset region (e.g., `US`, `EU`)
   - **Threads**: 8

4. Click **Test Connection** — you should see a green checkmark

---

## Step 4: Configure Project Variables

1. Go to **Account Settings → Projects → Your Project**
2. Click **Environment Variables** or edit `dbt_project.yml` in the Cloud IDE
3. Set these variables:

| Variable | Value | Example |
|---|---|---|
| `ga4_database` | Your GCP project ID | `my-company-12345` |
| `ga4_schema` | Your GA4 BigQuery dataset | `analytics_301234567` |
| `ga4_start_date` | How far back to process | `20240101` |

> **Tip:** You can also set these as environment-level variables in dbt Cloud, which keeps them out of the code and lets you use different values for dev vs prod.

### Setting Environment Variables in dbt Cloud

1. Go to **Deploy → Environments**
2. Click into your environment (e.g., "Production")
3. Under **Environment Variables**, add:
   - `DBT_VAR_ga4_database` = `my-company-12345`
   - `DBT_VAR_ga4_schema` = `analytics_301234567`

---

## Step 5: Set Up Environments

### Development Environment

1. Go to **Deploy → Environments** → **Create Environment**
2. Name: `Development`
3. Type: **Development**
4. Dataset: `dbt_dev` (keeps dev tables separate from production)
5. Click **Save**

### Production Environment

1. Click **Create Environment** again
2. Name: `Production`
3. Type: **Deployment**
4. Dataset: `dbt_prod`
5. Click **Save**

---

## Step 6: Run Your First Build

### Using the Cloud IDE

1. Click **Develop** in the top nav
2. The Cloud IDE opens with your project files
3. In the command bar at the bottom, run:

```
dbt deps
```

Then:

```
dbt seed
```

Then:

```
dbt run
```

Then:

```
dbt test
```

You'll see each model build with green checkmarks.

### Using a Job (Recommended)

1. Go to **Deploy → Jobs** → **Create Job**
2. Name: `Full Refresh Build`
3. Environment: `Production`
4. Commands:
   ```
   dbt deps
   dbt seed
   dbt run
   dbt test
   ```
5. Click **Save**, then **Run Now**

---

## Step 7: Schedule Daily Runs

GA4 exports new data to BigQuery daily. You need a scheduled job to keep your analytics tables current.

1. Go to **Deploy → Jobs** → **Create Job**
2. Configure:
   - **Name**: `Daily Incremental Run`
   - **Environment**: Production
   - **Commands**:
     ```
     dbt run
     dbt test
     ```
   - **Schedule**: Select **Cron Schedule**
   - **Cron**: `0 8 * * *` (runs at 8 AM UTC daily)

   > **Tip:** GA4 typically finishes its daily BigQuery export by 4-6 AM UTC. Schedule your dbt run for a few hours after to ensure all data is available.

3. Under **Notifications**:
   - Enable email alerts for failed runs
   - Optionally connect Slack for real-time notifications

4. Click **Save**

---

## Step 8: Browse Documentation

1. Go to **Deploy → Jobs** → click your completed job
2. Click **View Documentation** on a successful run
3. This opens hosted, interactive model documentation:
   - Browse all models with descriptions
   - View the lineage DAG (which models depend on others)
   - See column descriptions and tests
   - Share the docs URL with your team

---

## Step 9: Set Up Team Access (Optional)

1. Go to **Account Settings → Users**
2. Invite team members by email
3. Assign roles:
   - **Developer**: Can edit models in the Cloud IDE
   - **Analyst**: Can view docs and run results (read-only)
   - **Admin**: Full access

---

## Day-to-Day Workflow in dbt Cloud

| Task | Where | How |
|---|---|---|
| Check if today's data loaded | **Deploy → Run History** | Look for green checkmark on today's run |
| Investigate a test failure | **Deploy → Run History → Failed Run** | Click into the failed test to see details |
| Add a custom model | **Develop** (Cloud IDE) | Create a new `.sql` file, write SQL, run & test |
| View table documentation | **Explore** or **Documentation** | Browse models, columns, lineage |
| Run a one-off full refresh | **Deploy → Jobs → Full Refresh Build** | Click **Run Now** |

---

## Costs

dbt Cloud pricing (as of 2026):

| Plan | Price | Includes |
|---|---|---|
| **Developer** | Free | 1 seat, 1 project, manual runs |
| **Team** | ~$100/seat/month | Unlimited runs, scheduling, CI, multiple environments |
| **Enterprise** | Custom | SSO, audit logs, dedicated support |

The free Developer plan is sufficient for a single-person setup with manual daily runs. For automated scheduling and team access, you'll need the Team plan.

> **Note:** dbt Cloud costs are separate from BigQuery costs. Your BigQuery charges depend on query volume and data scanned.

---

## Troubleshooting

### "Could not connect to BigQuery"
- Verify your service account JSON key is valid
- Check that the service account has BigQuery Data Editor and Job User roles
- Ensure the dataset location in dbt Cloud matches your BigQuery dataset location

### "Repository not found"
- Re-authorize dbt Cloud's GitHub integration
- Make sure the repository is not private, or that dbt Cloud has access to private repos

### "Model failed: Not found: Dataset"
- The `ga4_schema` variable doesn't match your actual GA4 dataset name
- Check BigQuery Console for the correct dataset name

### Job runs but tables are empty
- Verify `ga4_start_date` is set to a date with actual data
- Check that GA4 BigQuery export is active and has exported tables

---

*Last updated: March 2026*
