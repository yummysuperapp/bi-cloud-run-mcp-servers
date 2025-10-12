#!/bin/bash

# Script para manejar las credenciales de BigQuery en Cloud Run

# Crear directorio para credenciales
mkdir -p /secret

# Si el secret está disponible como variable de entorno, guardarlo como archivo
if [ ! -z "$GOOGLE_APPLICATION_CREDENTIALS_JSON" ]; then
    echo "$GOOGLE_APPLICATION_CREDENTIALS_JSON" > /secret/credentials.json
    echo "✅ Credenciales guardadas en /secret/credentials.json"
    export GOOGLE_APPLICATION_CREDENTIALS=/secret/credentials.json
fi

# Si el secret ya existe como archivo, mostrar información
if [ -f "/secret/credentials.json" ]; then
    echo "✅ Archivo de credenciales encontrado en /secret/credentials.json"
    echo "📊 Proyecto configurado: production-yummy"
    echo "📂 Dataset configurado: dbt_rides"
else
    echo "⚠️  No se encontraron credenciales en /secret/credentials.json"
    echo "🔄 Usando autenticación predeterminada de Google Cloud"
    # No hacer exit, continuar con la autenticación predeterminada
fi

# Verificar que estamos en el directorio correcto
cd /app/dbt-mcp

# Ejecutar el comando original
exec uv run src/dbt_mcp/main.py "$@"