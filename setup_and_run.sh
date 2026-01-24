#!/bin/bash
# Setup Snowflake credentials and run dbt pipeline

# Set Snowflake credentials
export SNOWFLAKE_ACCOUNT="lnb78386.us-east-1"
export SNOWFLAKE_USER="diana"
export SNOWFLAKE_PASSWORD="Db523652365236"

echo "=========================================="
echo "🚀 Artemis Demo - dbt Pipeline"
echo "=========================================="
echo ""
echo "✅ Snowflake credentials set"
echo "Account: $SNOWFLAKE_ACCOUNT"
echo "User: $SNOWFLAKE_USER"
echo ""

# Run the main pipeline
bash run.sh
