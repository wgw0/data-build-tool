# GA4 BigQuery dbt Project - Helper Script
# Usage: .\handover\run.ps1 [setup|run|test|docs|fresh|clean]

param(
    [Parameter(Position=0)]
    [ValidateSet("setup", "run", "test", "docs", "fresh", "clean", "help")]
    [string]$Command = "help"
)

$ErrorActionPreference = "Stop"

# Navigate to project root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir
Set-Location $ProjectDir

function Show-Help {
    Write-Host ""
    Write-Host "GA4 BigQuery dbt Project" -ForegroundColor Cyan
    Write-Host "========================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage: .\handover\run.ps1 <command>"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  setup    " -NoNewline -ForegroundColor Green
    Write-Host "First-time setup (install packages, load seeds, build models, test)"
    Write-Host "  run      " -NoNewline -ForegroundColor Green
    Write-Host "Rebuild all models (daily use)"
    Write-Host "  test     " -NoNewline -ForegroundColor Green
    Write-Host "Run all data quality tests"
    Write-Host "  docs     " -NoNewline -ForegroundColor Green
    Write-Host "Generate and open interactive documentation"
    Write-Host "  fresh    " -NoNewline -ForegroundColor Green
    Write-Host "Full clean rebuild from scratch"
    Write-Host "  clean    " -NoNewline -ForegroundColor Green
    Write-Host "Remove build artifacts"
    Write-Host ""
}

switch ($Command) {
    "setup" {
        Write-Host "=== Installing dbt packages ===" -ForegroundColor Cyan
        dbt deps
        Write-Host ""
        Write-Host "=== Loading seed data ===" -ForegroundColor Cyan
        dbt seed
        Write-Host ""
        Write-Host "=== Building all models ===" -ForegroundColor Cyan
        dbt run
        Write-Host ""
        Write-Host "=== Running tests ===" -ForegroundColor Cyan
        dbt test
        Write-Host ""
        Write-Host "=== Setup complete! ===" -ForegroundColor Green
        Write-Host "Your analytics tables are now in BigQuery."
        Write-Host "Run '.\handover\run.ps1 docs' to browse interactive documentation."
    }
    "run" {
        dbt run
    }
    "test" {
        dbt test
    }
    "docs" {
        dbt docs generate
        dbt docs serve
    }
    "fresh" {
        dbt clean
        dbt deps
        dbt seed
        dbt run --full-refresh
        dbt test
    }
    "clean" {
        dbt clean
    }
    default {
        Show-Help
    }
}
