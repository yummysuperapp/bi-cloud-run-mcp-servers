# dbt MCP Server on Google Cloud Run

A Model Context Protocol (MCP) server that integrates with dbt projects and BigQuery, deployed on Google Cloud Run.

## Overview

This project deploys an MCP server that provides AI assistants (like Claude) with access to your dbt models, metrics, and BigQuery data warehouse through the dbt Cloud API. The server runs as a containerized service on Google Cloud Run with automatic scaling.

## Features

- **dbt Integration**: Full access to dbt models, tests, metrics, and documentation
- **BigQuery Connectivity**: Direct SQL queries against your data warehouse  
- **AI Assistant Integration**: Works with Claude and other MCP-compatible AI tools
- **Cloud Run Deployment**: Scalable, serverless deployment with automatic scaling
- **SSE Transport**: Server-Sent Events for real-time communication
- **Multi-Environment Support**: Development and production configurations
- **Job Management**: Trigger, monitor, and debug dbt Cloud jobs
- **Artifact Access**: Download and analyze dbt run artifacts

## Architecture

```
AI Assistant (Claude/VS Code) + MCP Extension
    ↓ (SSE Transport)
Cloud Run Service (dbt-mcp-server)
    ↓
dbt Cloud API + BigQuery
```

## Prerequisites

- Google Cloud Project with billing enabled
- Google Cloud CLI (`gcloud`) installed and configured
- Docker (for local testing)
- VS Code with MCP extension (or Claude Desktop)
- GitHub personal access token (for private dbt repositories)
- dbt Cloud account and API token
- BigQuery service account with appropriate permissions

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/bi-cloud-run-mcp-servers.git
cd bi-cloud-run-mcp-servers
```

### 2. Configure Your Deployment

Create a `config.local.sh` file from the example:

```bash
cp config.example.sh config.local.sh
```

Edit `config.local.sh` with your values:

```bash
# Google Cloud Configuration
export PROJECT_ID="your-gcp-project-id"
export REGION="us-central1"
export SERVICE_NAME="dbt-mcp-server"

# dbt Cloud Configuration
export DBT_HOST="cloud.getdbt.com"
export DBT_PROD_ENV_ID="your-dbt-env-id"
export DBT_USER_ID="your-dbt-user-id"
export DBT_TOKEN="your-dbt-api-token"

# GitHub Configuration
export GITHUB_TOKEN="ghp_your_github_token"
export GITHUB_REPO="your-org/your-dbt-project"

# Container Configuration (optional)
export MEMORY="2Gi"
export CPU="2"
export MAX_INSTANCES="5"
export TIMEOUT="3600"
```

### 3. Set Up BigQuery Credentials

Create your BigQuery service account key file and save it in the project directory:

```bash
# Development credentials
cp your-service-account.json yummy-development.json
```

**Important**: These credential files are automatically excluded from git via `.gitignore`.

### 4. Configure dbt Profile

Create your `profiles.yml` based on the example:

```bash
cp profiles.yml.example profiles.yml
```

Edit `profiles.yml` with your BigQuery configuration:

```yaml
default:
  outputs:
    dev:
      dataset: your_dataset
      keyfile: /app/credentials/yummy-development.json
      method: service-account
      project: your-gcp-project-id
      threads: 4
      type: bigquery
  target: dev
```

### 5. Update Dockerfile

Edit the `Dockerfile` to use your dbt repository URL:

```dockerfile
# Line 21: Replace with your dbt repository URL
RUN git clone https://${GITHUB_TOKEN}@github.com/your-org/your-dbt-project.git /app/bi-dbt-bigquery-models
```

### 6. Deploy to Cloud Run

Source your configuration and deploy:

```bash
source config.local.sh
./deploy-cloud-run.sh
```

Or pass parameters directly:

```bash
./deploy-cloud-run.sh YOUR_PROJECT_ID us-central1 YOUR_GITHUB_TOKEN
```

### 7. Configure Your AI Assistant

#### For Claude Desktop

Add to your Claude Desktop MCP configuration (`~/Library/Application Support/Claude/claude_desktop_config.json` on macOS):

```json
{
  "mcpServers": {
    "dbt-cloud-run": {
      "command": "mcp-client-sse",
      "args": ["https://your-service-url-here.run.app/sse"]
    }
  }
}
```

#### For VS Code

Add to your VS Code MCP settings:

```json
{
  "servers": {
    "dbt-cloud-run": {
      "transport": {
        "type": "sse", 
        "url": "https://your-service-url-here.run.app/sse"
      }
    }
  }
}
```

## Local Testing

Test the container locally before deployment:

```bash
./test-local.sh YOUR_GITHUB_TOKEN
```

This builds and runs the container locally on port 8080.

## Available MCP Tools

### dbt Model Management
- `get_all_models` - List all dbt models with metadata
- `get_mart_models` - List only mart/presentation layer models
- `get_model_details` - Get detailed model information including compiled SQL
- `get_model_health` - Check model execution status and data freshness
- `get_model_parents` - Get upstream dependencies (parent models)
- `get_model_children` - Get downstream dependencies (child models)

### dbt Metrics & Semantic Layer
- `list_metrics` - List available dbt metrics
- `get_dimensions` - Get available dimensions for metrics
- `get_entities` - Get available entities for metrics
- `query_metrics` - Query metrics with dimensions and filters
- `get_metrics_compiled_sql` - Get compiled SQL for metric queries

### dbt Operations
- `run` - Execute dbt run commands with selectors
- `test` - Run dbt tests with selectors
- `build` - Execute dbt build (run + test in DAG order)
- `compile` - Compile dbt models without execution
- `parse` - Parse and validate dbt project structure
- `show` - Execute arbitrary SQL queries against the data warehouse

### Job Management
- `list_jobs` - List all dbt Cloud jobs
- `get_job_details` - Get detailed job configuration
- `trigger_job_run` - Trigger a job run with optional overrides
- `list_jobs_runs` - List job run history with filtering
- `get_job_run_details` - Get detailed run information
- `cancel_job_run` - Cancel running or queued jobs
- `retry_job_run` - Retry failed jobs from point of failure

### Artifacts & Debugging
- `list_job_run_artifacts` - List available run artifacts
- `get_job_run_artifact` - Download specific artifacts (manifest.json, catalog.json, etc.)
- `get_job_run_error` - Get focused error information for failed runs
- `get_exposures` - List all dbt exposures
- `get_exposure_details` - Get detailed exposure information

## Project Structure

```
├── Dockerfile                    # Container definition with dbt setup
├── README.md                     # This file
├── LICENSE                       # MIT License
├── cloudbuild.yaml              # Google Cloud Build configuration
├── deploy-cloud-run.sh          # Main deployment script
├── test-local.sh               # Local testing script
├── main.py                      # Custom MCP server entry point
├── config.example.sh           # Example configuration file
├── profiles.yml.example        # Example dbt profile
├── service-account.json.example # Example service account structure
├── .env.example                # Example environment variables
├── .gitignore                  # Git ignore rules (excludes credentials)
└── .gcloudignore              # Cloud Build ignore rules
```

## Configuration Details

### Environment Variables

The deployment automatically sets these environment variables in Cloud Run:

- `ENVIRONMENT` - Environment name (production/development)
- `DBT_HOST` - dbt Cloud host URL (default: cloud.getdbt.com)
- `DBT_PROD_ENV_ID` - dbt Cloud environment ID  
- `DBT_USER_ID` - dbt Cloud user ID
- `DBT_TOKEN` - dbt Cloud API token
- `DBT_CLI_TIMEOUT` - Timeout for dbt CLI commands (default: 120s)
- `DBT_PROJECT_DIR` - Path to dbt project in container
- `DBT_PATH` - Path to dbt binary
- `DBT_PROFILES_DIR` - Path to dbt profiles directory
- `DISABLE_DBT_CLI` - Set to "true" to disable CLI operations (default: false)

### Security Best Practices

1. **Never commit credentials to git**:
   - Service account keys are excluded via `.gitignore`
   - Use example files to show structure only
   - Keep `config.local.sh` out of version control

2. **Use Secret Manager for production**:
   ```bash
   # Create secrets
   echo -n "your-dbt-token" | gcloud secrets create dbt-token --data-file=-
   
   # Update Cloud Run deployment to use secrets
   gcloud run services update dbt-mcp-server \
     --update-secrets=DBT_TOKEN=dbt-token:latest
   ```

3. **Restrict service account permissions**:
   - Grant minimum BigQuery permissions needed
   - Use separate service accounts for dev/prod
   - Regularly rotate credentials

4. **Enable Cloud Run authentication** (optional):
   ```bash
   gcloud run services update dbt-mcp-server \
     --no-allow-unauthenticated
   ```

## How to Get Required Credentials

### dbt Cloud API Token
1. Log in to dbt Cloud
2. Go to Profile Settings → API Access
3. Create a new API token
4. Copy the token (starts with `dbtc_`)

### dbt Environment ID
1. Go to your dbt Cloud project
2. Navigate to Deploy → Environments
3. Click on your environment
4. Copy the ID from the URL (e.g., `57536` from `.../environments/57536`)

### GitHub Personal Access Token
1. Go to GitHub Settings → Developer settings → Personal access tokens
2. Generate new token (classic)
3. Grant `repo` scope for private repositories
4. Copy the token (starts with `ghp_`)

### BigQuery Service Account
1. Go to Google Cloud Console → IAM & Admin → Service Accounts
2. Create or select a service account
3. Grant roles: BigQuery Data Viewer, BigQuery Job User
4. Create and download JSON key
5. Save as `yummy-development.json` in project root

## Troubleshooting

### Build Issues

**GitHub Token Invalid**:
```bash
# Verify token has repository access
curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user
```

**dbt deps fails**:
```bash
# Check packages.yml in your dbt project
# Ensure all package versions are compatible
```

**Service account file not found**:
```bash
# Verify file exists and is named correctly
ls -l *.json
# Check Dockerfile COPY command matches your filename
```

### Runtime Issues

**BigQuery Access Denied**:
```bash
# Verify service account has necessary roles
gcloud projects get-iam-policy $PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:YOUR_SA_EMAIL"
```

**dbt Cloud API Errors**:
```bash
# Test API token
curl -H "Authorization: Bearer $DBT_TOKEN" \
  https://cloud.getdbt.com/api/v2/accounts/
```

**Container Crashes**:
```bash
# View detailed logs
gcloud run services logs read dbt-mcp-server \
  --region=$REGION \
  --project=$PROJECT_ID \
  --limit=100
```

### MCP Connection Issues

**Connection Timeout**:
- Verify Cloud Run service is running and healthy
- Check service URL is correct (includes `/sse` endpoint)
- Ensure service allows unauthenticated access

**SSE Connection Drops**:
- Increase Cloud Run timeout if queries are long-running
- Check Cloud Run memory limits
- Review application logs for errors

**Tools Not Available**:
- Restart your AI assistant after configuration changes
- Verify MCP configuration syntax
- Check that the service URL is accessible

## Monitoring and Maintenance

### View Logs

```bash
# Real-time logs
gcloud run services logs tail dbt-mcp-server --region=$REGION

# Historical logs
gcloud run services logs read dbt-mcp-server \
  --region=$REGION \
  --limit=100
```

### Cloud Console

Monitor your deployment at:
```
https://console.cloud.google.com/run?project=YOUR_PROJECT_ID
```

### Update Deployment

After making changes, redeploy:

```bash
source config.local.sh
./deploy-cloud-run.sh
```

### Scale Configuration

Adjust resources in `config.local.sh`:

```bash
export MEMORY="4Gi"        # Increase for large queries
export CPU="4"              # More CPU for parallel operations
export MAX_INSTANCES="10"   # Handle more concurrent requests
```

## Cost Optimization

Cloud Run pricing is based on:
- CPU and memory allocation
- Request duration
- Number of requests
- Network egress

Tips to reduce costs:
1. Set `min-instances=0` to scale to zero when idle
2. Use appropriate memory/CPU sizes
3. Implement request caching where possible
4. Monitor and optimize long-running queries

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test locally with `./test-local.sh`
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Development Guidelines

- Never commit credentials or tokens
- Update documentation for new features
- Follow existing code style
- Test changes thoroughly before submitting

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Support

- **Issues**: Open an issue on GitHub
- **dbt MCP Documentation**: https://github.com/dbt-labs/dbt-mcp
- **Cloud Run Documentation**: https://cloud.google.com/run/docs
- **MCP Protocol**: https://modelcontextprotocol.io

## Acknowledgments

- Built on [dbt-mcp](https://github.com/dbt-labs/dbt-mcp) by dbt Labs
- Uses the [Model Context Protocol](https://modelcontextprotocol.io)
- Deployed on Google Cloud Run
