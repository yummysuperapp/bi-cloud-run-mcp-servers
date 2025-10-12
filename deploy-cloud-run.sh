#!/bin/bash

# Cloud Run Deployment Script for dbt MCP Server
# Usage: ./deploy-cloud-run.sh [PROJECT_ID] [REGION] [GITHUB_TOKEN]
# Or source config.local.sh before running

set -e

# Change to script directory
cd "$(dirname "$0")"

# Source local config if it exists
if [ -f "config.local.sh" ]; then
    echo "📋 Loading configuration from config.local.sh..."
    source config.local.sh
fi

# Default configuration
DEFAULT_PROJECT="${PROJECT_ID:-your-project-id}"
DEFAULT_REGION="${REGION:-us-central1}"
DEFAULT_SERVICE_NAME="${SERVICE_NAME:-dbt-mcp-server}"

# Parameters (command line takes precedence)
PROJECT_ID=${1:-$DEFAULT_PROJECT}
REGION=${2:-$DEFAULT_REGION}
SERVICE_NAME=${DEFAULT_SERVICE_NAME}
GITHUB_TOKEN=${3:-$GITHUB_TOKEN}

IMAGE_NAME="gcr.io/${PROJECT_ID}/${SERVICE_NAME}"

echo "🚀 Deploying dbt MCP Server to Cloud Run"
echo "   Project: $PROJECT_ID"
echo "   Region: $REGION"
echo "   Service: $SERVICE_NAME"
echo ""

# Check if gcloud is installed and authenticated
if ! command -v gcloud &> /dev/null; then
    echo "❌ Error: gcloud CLI is not installed"
    echo "   Install gcloud: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check authentication
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo "❌ Error: No active gcloud accounts"
    echo "   Run: gcloud auth login"
    exit 1
fi

# Check required environment variables
if [ -z "$GITHUB_TOKEN" ]; then
    echo "❌ Error: GITHUB_TOKEN is required"
    echo "   Usage: ./deploy-cloud-run.sh [PROJECT_ID] [REGION] [GITHUB_TOKEN]"
    echo "   Or set in config.local.sh"
    exit 1
fi

if [ -z "$DBT_TOKEN" ]; then
    echo "❌ Error: DBT_TOKEN is required"
    echo "   Set in config.local.sh or export DBT_TOKEN=your_token"
    exit 1
fi

# Validate project ID
if [ "$PROJECT_ID" = "your-project-id" ]; then
    echo "❌ Error: Please configure PROJECT_ID in config.local.sh"
    exit 1
fi

# Configure project
echo "📋 Configuring project $PROJECT_ID..."
gcloud config set project $PROJECT_ID

# Enable required APIs
echo "🔧 Enabling required APIs..."
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com

# Build image in Cloud Build
echo "🏗️  Building Docker image in Cloud Build..."
gcloud builds submit \
    --config cloudbuild.yaml \
    --substitutions _GITHUB_TOKEN=$GITHUB_TOKEN,_IMAGE_NAME=$IMAGE_NAME \
    --timeout=30m \
    .

# Deploy to Cloud Run
echo "🚀 Deploying to Cloud Run..."
gcloud run deploy $SERVICE_NAME \
    --image $IMAGE_NAME \
    --platform managed \
    --region $REGION \
    --allow-unauthenticated \
    --memory=${MEMORY:-2Gi} \
    --cpu=${CPU:-2} \
    --timeout=${TIMEOUT:-3600} \
    --concurrency=10 \
    --max-instances=${MAX_INSTANCES:-5} \
    --min-instances=0 \
    --port=8080 \
    --set-env-vars="ENVIRONMENT=${ENVIRONMENT:-production}" \
    --set-env-vars="DBT_HOST=${DBT_HOST:-cloud.getdbt.com}" \
    --set-env-vars="DBT_PROD_ENV_ID=${DBT_PROD_ENV_ID}" \
    --set-env-vars="DBT_USER_ID=${DBT_USER_ID}" \
    --set-env-vars="DBT_TOKEN=${DBT_TOKEN}" \
    --set-env-vars="DBT_CLI_TIMEOUT=${DBT_CLI_TIMEOUT:-120}" \
    --set-env-vars="DBT_PROJECT_DIR=/app/bi-dbt-bigquery-models" \
    --set-env-vars="DBT_PATH=/app/bi-dbt-bigquery-models/dbt_env/bin/dbt" \
    --set-env-vars="DBT_PROFILES_DIR=/root/.dbt" \
    --set-env-vars="DISABLE_DBT_CLI=false"

# Get service URL
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region=$REGION --format="value(status.url)")

echo ""
echo "✅ Deployment completed successfully!"
echo "   🌐 Service URL: $SERVICE_URL"
echo "   📊 Console: https://console.cloud.google.com/run/detail/$REGION/$SERVICE_NAME/metrics?project=$PROJECT_ID"
echo ""
echo "🔗 To connect from VS Code, use this URL in your MCP configuration:"
echo "   $SERVICE_URL"
echo ""
echo "📝 To view logs:"
echo "   gcloud run services logs read $SERVICE_NAME --region=$REGION --project=$PROJECT_ID"
