#!/bin/bash

# Cloud Run Deployment Script for dbt MCP Server (Secure HTTP)
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
DEFAULT_SERVICE_NAME="${SERVICE_NAME:-dbt-mcp}"

# Parameters (command line takes precedence)
PROJECT_ID=${1:-$DEFAULT_PROJECT}
REGION=${2:-$DEFAULT_REGION}
SERVICE_NAME=${DEFAULT_SERVICE_NAME}
GITHUB_TOKEN=${3:-$GITHUB_TOKEN}

IMAGE_NAME="gcr.io/${PROJECT_ID}/${SERVICE_NAME}"

echo "🚀 Deploying dbt MCP Server to Cloud Run (Secure HTTP)"
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

# Generate MCP authentication token if not exists
if [ -z "$MCP_AUTH_TOKEN" ]; then
    echo "⚠️  MCP_AUTH_TOKEN not found, generating secure token..."
    MCP_AUTH_TOKEN=$(openssl rand -base64 32)
    echo "🔐 Generated MCP Auth Token: $MCP_AUTH_TOKEN"
    echo "💾 IMPORTANT: Save this token! You'll need it for Claude configuration."
    echo ""
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
gcloud services enable secretmanager.googleapis.com

# Create/update Secret Manager secret for MCP auth token
echo "🔐 Creating/updating Secret Manager secret for MCP authentication..."
if gcloud secrets describe mcp-auth-token --project=$PROJECT_ID &> /dev/null; then
    echo "   Secret 'mcp-auth-token' exists, updating..."
    echo -n "$MCP_AUTH_TOKEN" | gcloud secrets versions add mcp-auth-token \
        --data-file=- \
        --project=$PROJECT_ID
else
    echo "   Creating new secret 'mcp-auth-token'..."
    echo -n "$MCP_AUTH_TOKEN" | gcloud secrets create mcp-auth-token \
        --data-file=- \
        --replication-policy="automatic" \
        --project=$PROJECT_ID
fi

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
    --set-env-vars="DISABLE_DBT_CLI=false" \
    --update-secrets=MCP_AUTH_TOKEN=mcp-auth-token:latest

# Get service URL
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region=$REGION --format="value(status.url)")

echo ""
echo "✅ Deployment completed successfully!"
echo "   🌐 Service URL: $SERVICE_URL"
echo "   📊 Console: https://console.cloud.google.com/run/detail/$REGION/$SERVICE_NAME/metrics?project=$PROJECT_ID"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔒 SECURE HTTP CONFIGURATION (MCP 2025-06-18)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🔐 Your authentication token:"
echo "   $MCP_AUTH_TOKEN"
echo ""
echo "📝 Claude Desktop Configuration:"
echo "   File: ~/Library/Application Support/Claude/claude_desktop_config.json"
echo ""
cat << EOFCONFIG
{
  "mcpServers": {
    "dbt-cloud-run": {
      "transport": {
        "type": "http",
        "url": "$SERVICE_URL",
        "headers": {
          "Authorization": "Bearer $MCP_AUTH_TOKEN"
        }
      }
    }
  }
}
EOFCONFIG
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📝 To view logs:"
echo "   gcloud run services logs read $SERVICE_NAME --region=$REGION --project=$PROJECT_ID"
echo ""
echo "⚠️  IMPORTANT: Save the authentication token in a secure location!"
