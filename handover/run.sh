#!/usr/bin/env bash
set -euo pipefail

# GA4 BigQuery dbt Project — Helper Script
# Usage: ./handover/run.sh [setup|run|test|docs|fresh|clean]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

show_help() {
    echo ""
    echo "GA4 BigQuery dbt Project"
    echo "========================"
    echo ""
    echo "Usage: ./handover/run.sh <command>"
    echo ""
    echo "Commands:"
    echo "  setup    First-time setup (install packages, load seeds, build models, test)"
    echo "  run      Rebuild all models (daily use)"
    echo "  test     Run all data quality tests"
    echo "  docs     Generate and open interactive documentation"
    echo "  fresh    Full clean rebuild from scratch"
    echo "  clean    Remove build artifacts"
    echo ""
}

case "${1:-help}" in
    setup)
        echo "=== Installing dbt packages ==="
        dbt deps
        echo ""
        echo "=== Loading seed data ==="
        dbt seed
        echo ""
        echo "=== Building all models ==="
        dbt run
        echo ""
        echo "=== Running tests ==="
        dbt test
        echo ""
        echo "=== Setup complete! ==="
        echo "Your analytics tables are now in BigQuery."
        echo "Run './handover/run.sh docs' to browse interactive documentation."
        ;;
    run)
        dbt run
        ;;
    test)
        dbt test
        ;;
    docs)
        dbt docs generate
        dbt docs serve
        ;;
    fresh)
        dbt clean
        dbt deps
        dbt seed
        dbt run --full-refresh
        dbt test
        ;;
    clean)
        dbt clean
        ;;
    *)
        show_help
        ;;
esac
