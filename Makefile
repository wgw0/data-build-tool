.PHONY: setup run test docs clean fresh help

# Default target
help: ## Show this help message
	@echo ""
	@echo "GA4 BigQuery dbt Project"
	@echo "========================"
	@echo ""
	@echo "Available commands:"
	@echo ""
	@echo "  make setup    Install dependencies and build everything from scratch"
	@echo "  make run      Rebuild all models (daily use)"
	@echo "  make test     Run all data quality tests"
	@echo "  make docs     Generate and serve interactive documentation"
	@echo "  make fresh    Full clean rebuild (deps + seed + run + test)"
	@echo "  make clean    Remove build artifacts"
	@echo ""

setup: ## First-time setup: install packages, load seeds, build all models, run tests
	@echo "=== Installing dbt packages ==="
	dbt deps
	@echo ""
	@echo "=== Loading seed data ==="
	dbt seed
	@echo ""
	@echo "=== Building all models ==="
	dbt run
	@echo ""
	@echo "=== Running tests ==="
	dbt test
	@echo ""
	@echo "=== Setup complete! ==="
	@echo "Your analytics tables are now in BigQuery."
	@echo "Run 'make docs' to browse interactive documentation."

run: ## Build all models (run this daily)
	dbt run

test: ## Run all schema and data tests
	dbt test

docs: ## Generate and serve interactive documentation
	dbt docs generate
	dbt docs serve

clean: ## Remove dbt build artifacts
	dbt clean

fresh: ## Full rebuild from scratch (clean + deps + seed + run + test)
	dbt clean
	dbt deps
	dbt seed
	dbt run --full-refresh
	dbt test
