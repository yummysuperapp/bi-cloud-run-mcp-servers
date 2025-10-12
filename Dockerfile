# Use Python 3.12 slim image
FROM python:3.12-slim

# Set working directory
WORKDIR /app

# Install system dependencies needed for git and virtual environments
RUN apt-get update && apt-get install -y \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install uv for fast Python package installation
RUN pip install uv

# Argument for GitHub token (to be passed during build)
ARG GITHUB_TOKEN

# Clone the private dbt repository using the GitHub token
RUN git clone https://${GITHUB_TOKEN}@github.com/yummysuperapp/bi-dbt-bigquery-models.git /app/bi-dbt-bigquery-models

# Enter the cloned repository and set up dbt environment
WORKDIR /app/bi-dbt-bigquery-models

# Create virtual environment and install dbt packages
RUN python -m venv dbt_env && \
    . dbt_env/bin/activate && \
    pip install dbt-core dbt-bigquery && \
    dbt deps

# Return to root directory
WORKDIR /app

# Clone the dbt-mcp repository from GitHub
RUN git clone https://github.com/dbt-labs/dbt-mcp.git

# Enter the dbt-mcp directory
WORKDIR /app/dbt-mcp

# Set version environment variable to avoid setuptools-scm issues
ENV SETUPTOOLS_SCM_PRETEND_VERSION=1.0.0

# Set dbt environment variables
ENV DBT_PROJECT_DIR=/app/bi-dbt-bigquery-models
ENV DBT_PATH=/app/bi-dbt-bigquery-models/dbt_env/bin/dbt

# Install dependencies and the package from the cloned repository
RUN uv sync --frozen && uv pip install -e .

# Copy our custom main.py file
COPY main.py src/dbt_mcp/main.py

# Create dbt profiles directory and copy profiles.yml
RUN mkdir -p /root/.dbt
COPY profiles.yml /root/.dbt/profiles.yml

# CRITICAL: Copy BigQuery credentials for dbt
# This file contains the service account credentials for accessing BigQuery
RUN mkdir -p /app/credentials
COPY yummy-development.json /app/credentials/yummy-development.json

# Create credentials directory for Secret Manager mount
RUN mkdir -p /secret

# Create a directory for user projects (to be mounted)
RUN mkdir -p /workspace

# Copy the entrypoint script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Expose MCP port (Cloud Run uses PORT env var, defaulting to 8080)
EXPOSE 8080

# Set working directory and use custom entrypoint
WORKDIR /app/dbt-mcp
ENTRYPOINT ["/app/entrypoint.sh"]
