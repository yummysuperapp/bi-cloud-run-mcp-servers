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

## Quick Start

1. Clone this repository
2. Configure your deployment settings
3. Deploy to Cloud Run
4. Connect your AI assistant

## License

MIT License