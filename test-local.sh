#!/bin/bash

# Script para probar el servidor MCP localmente antes del despliegue
# Uso: ./test-local.sh [GITHUB_TOKEN]

set -e

# Cambiar al directorio del script
cd "$(dirname "$0")"

GITHUB_TOKEN=${1}
IMAGE_NAME="dbt-mcp-server:local"

echo "🧪 Probando dbt MCP Server localmente"
echo ""

# Verificar que Docker esté corriendo
if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker no está corriendo"
    echo "   Inicia Docker Desktop o el daemon de Docker"
    exit 1
fi

# Verificar GitHub token
if [ -z "$GITHUB_TOKEN" ]; then
    echo "❌ Error: GITHUB_TOKEN es requerido"
    echo "   Uso: ./test-local.sh [GITHUB_TOKEN]"
    exit 1
fi

# Construir imagen localmente
echo "🏗️  Construyendo imagen Docker localmente..."
docker build --build-arg GITHUB_TOKEN=$GITHUB_TOKEN -t $IMAGE_NAME .

# Ejecutar contenedor
echo "🚀 Ejecutando contenedor localmente..."
echo "   Servidor disponible en: http://localhost:8080"
echo "   Presiona Ctrl+C para detener"
echo ""

docker run --rm -p 8080:8080 \
    --env-file .env.production \
    --name dbt-mcp-local \
    $IMAGE_NAME