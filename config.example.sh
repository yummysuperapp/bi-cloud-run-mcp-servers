# Configuration file for deployment script
# Copy this file to config.local.sh and modify with your values

# Google Cloud Project Configuration
export PROJECT_ID="your-project-id"
export REGION="us-central1"
export SERVICE_NAME="dbt-mcp"

# dbt Cloud Configuration
export DBT_HOST="cloud.getdbt.com"
export DBT_PROD_ENV_ID="your-dbt-env-id"
export DBT_USER_ID="your-dbt-user-id"
export DBT_TOKEN="your-dbt-api-token"

# GitHub Configuration
export GITHUB_TOKEN="your-github-token"
export GITHUB_REPO="your-org/your-dbt-project"

# Container Configuration
export MEMORY="2Gi"
export CPU="2"
export MAX_INSTANCES="5"
export TIMEOUT="3600"