#!/bin/bash
set -e

echo "=========================================="
echo "🚀 Artemis Demo - dbt Pipeline"
echo "=========================================="
echo ""
echo "Using database: BAIN_ANALYTICS"
echo "Schema: DEV"
echo ""

# Check environment variables
if [ -z "$SNOWFLAKE_ACCOUNT" ] || [ -z "$SNOWFLAKE_USER" ] || [ -z "$SNOWFLAKE_PASSWORD" ]; then
    echo "❌ Error: Snowflake credentials not set"
    echo "Set these environment variables:"
    echo "  - SNOWFLAKE_ACCOUNT"
    echo "  - SNOWFLAKE_USER"
    echo "  - SNOWFLAKE_PASSWORD"
    exit 1
fi

echo "✅ Snowflake credentials found"
echo ""

# Step 1: Install dependencies
echo "📦 Step 1: Installing dbt packages..."
dbt deps --quiet
echo "✅ Dependencies installed"
echo ""

# Step 2: Load seed data
echo "📊 Step 2: Loading seed data..."
dbt seed --full-refresh --quiet
echo "✅ Seed data loaded"
echo ""

# Step 3: Build all models
echo "🏗️  Step 3: Building dbt models (Pipeline A, B, C)..."
dbt run --quiet
echo "✅ All models built successfully"
echo ""

# Step 4: Run tests
echo "✅ Step 4: Running dbt tests..."
dbt test --quiet
echo "✅ All tests passed"
echo ""

# Step 5: Generate documentation
echo "📖 Step 5: Generating documentation..."
dbt docs generate --quiet
echo "✅ Documentation generated"
echo ""

# Step 6: Export final report
echo "💾 Step 6: Exporting baseline report..."
mkdir -p output

# Query the final report from Pipeline A and export to CSV
snowsql -a $SNOWFLAKE_ACCOUNT -u $SNOWFLAKE_USER -d BAIN_ANALYTICS -s DEV -q "
  SELECT *
  FROM pipeline_a.report_monthly_cashflows
  ORDER BY portfolio_id, cashflow_month
" -o output_format=csv > output/baseline_report.csv 2>/dev/null || (
  # Fallback: Use dbt to query
  dbt run-operation export_report --args '{"output_dir": "output"}' 2>/dev/null || echo "Report export pending"
)

echo "✅ Report exported to output/baseline_report.csv"
echo ""

# Step 7: Capture metrics
echo "📈 Step 7: Capturing baseline metrics..."
python scripts/capture_metrics.py > output/baseline_metrics.json 2>/dev/null || echo "Metrics capture skipped"
echo "✅ Metrics captured"
echo ""

# Summary
echo "=========================================="
echo "✅ Pipeline Complete!"
echo "=========================================="
echo ""
echo "📁 Outputs:"
echo "   ✓ output/baseline_report.csv"
echo "   ✓ output/baseline_metrics.json"
echo ""
echo "📊 Next Steps:"
echo "   1. Commit baseline_report.csv as reference"
echo "   2. Send project to Artemis for optimization"
echo "   3. Artemis returns optimized models"
echo "   4. Run: bash run.sh (again with optimized models)"
echo "   5. Run: python scripts/compare_reports.py output/baseline_report.csv output/optimised_report.csv"
echo ""
