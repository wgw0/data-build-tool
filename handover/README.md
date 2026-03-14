# Client Handover Package

This folder contains everything your client needs to get started with their GA4 BigQuery analytics pipeline.

## Documents

| Document | Who It's For | What It Covers |
|---|---|---|
| [What This Project Does](what_this_project_does.md) | **Everyone** | Plain-English explainer — what it is, why it matters, what you get |
| [Client Onboarding Guide](client_onboarding_guide.md) | **Setup person** | Step-by-step installation and configuration |
| [dbt Cloud Setup Guide](dbt_cloud_setup.md) | **Teams preferring a UI** | Visual interface setup, scheduling, team access |
| [Looker Studio Queries](looker_studio_queries.md) | **Analysts / Dashboard builders** | 12 ready-to-paste SQL queries for common reports |

## Scripts

| Script | Platform | Usage |
|---|---|---|
| [run.sh](run.sh) | Mac / Linux | `./handover/run.sh setup` |
| [run.ps1](run.ps1) | Windows | `.\handover\run.ps1 setup` |

There's also a [Makefile](../Makefile) at the project root: `make setup`, `make run`, `make test`, `make docs`.

## Recommended Client Workflow

1. **Start here** → [What This Project Does](what_this_project_does.md)
2. **Set it up** → [Client Onboarding Guide](client_onboarding_guide.md) or [dbt Cloud Setup Guide](dbt_cloud_setup.md)
3. **Build dashboards** → [Looker Studio Queries](looker_studio_queries.md)
