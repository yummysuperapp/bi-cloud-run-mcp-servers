# 🚀 GitHub Actions CI/CD Setup

Este documento explica cómo configurar el CI/CD automático para el dbt MCP Server usando GitHub Actions.

## 📋 Resumen de Cambios

Se adaptó el workflow del proyecto `bi-cloud-run-bigquery-extract-load` con los siguientes cambios mínimos:

### ✅ Cambios Principales

1. **Registry**: Cambio de Artifact Registry a Container Registry (gcr.io)
   - Original: `us-central1-docker.pkg.dev/raw-superapp/cloud-run-source-deploy/`
   - Nuevo: `gcr.io/raw-superapp/`

2. **Tipo de Despliegue**: Cloud Run Jobs → Cloud Run Service
   - Original: `gcloud run jobs deploy` con `--execute-now`
   - Nuevo: `gcloud run deploy` con configuración de servicio HTTP

3. **Configuración de Servicio**: Adaptado para servidor MCP
   - Puerto: 8080
   - Timeout: 3600s (1 hora para consultas largas)
   - Concurrency: 10 solicitudes simultáneas
   - Variables de entorno específicas de dbt

4. **Sin descarga de GCS**: Las credenciales se incluyen en el build
   - Original: Descarga de `credentials.json` desde GCS
   - Nuevo: Credenciales embebidas en la imagen durante el build

### 🔄 Estructura Mantenida

- ✅ Mismo trigger (push a main)
- ✅ Misma autenticación con service account
- ✅ Mismo flujo: autenticar → configurar Docker → build → push → deploy
- ✅ Mismos emojis y estructura de pasos
- ✅ Misma cuenta de servicio: `kustomer@raw-superapp.iam.gserviceaccount.com`
- ✅ Mismo proyecto: `raw-superapp`
- ✅ Misma región: `us-central1`

## 🔐 Secrets Necesarios en GitHub

Debes configurar los siguientes secrets en tu repositorio de GitHub:

### 1. Ir a Configuración de Secrets

```
https://github.com/yummysuperapp/bi-cloud-run-mcp-servers/settings/secrets/actions
```

### 2. Agregar los siguientes secrets:

| Secret Name | Descripción | Dónde obtenerlo |
|-------------|-------------|-----------------|
| `GCR_JSON_KEY` | Service account key de Google Cloud | GCP Console → IAM → Service Accounts → kustomer@raw-superapp.iam.gserviceaccount.com → Keys |
| `GITHUB_TOKEN_PRIVATE` | GitHub Personal Access Token para clonar repos privados | GitHub Settings → Developer settings → Personal access tokens |
| `DBT_PROD_ENV_ID` | ID del ambiente de producción en dbt Cloud | dbt Cloud → Deploy → Environments → (copiar ID de la URL) |
| `DBT_USER_ID` | Tu user ID en dbt Cloud | dbt Cloud → Profile Settings |
| `DBT_TOKEN` | Token de API de dbt Cloud | dbt Cloud → Profile Settings → API Access |

### 3. Formato de los Secrets

#### GCR_JSON_KEY
```json
{
  "type": "service_account",
  "project_id": "raw-superapp",
  "private_key_id": "...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "kustomer@raw-superapp.iam.gserviceaccount.com",
  ...
}
```

#### GITHUB_TOKEN_PRIVATE
```
ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

#### DBT_PROD_ENV_ID
```
57536
```

#### DBT_USER_ID
```
12345
```

#### DBT_TOKEN
```
dbtc_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

## 🔧 Cómo Funciona el Workflow

### Trigger
```yaml
on:
  push:
    branches:
      - main
```
- Se ejecuta automáticamente al hacer push a la rama `main`

### Pasos del Workflow

1. **📥 Clonar el repositorio**
   - Usa `actions/checkout@v4` para obtener el código

2. **🔑 Crear archivo de credenciales**
   - Crea el archivo JSON del service account desde el secret

3. **🔐 Autenticarse en Google Cloud**
   - Activa el service account con `gcloud auth activate-service-account`
   - Configura el proyecto `raw-superapp`

4. **🛠️ Configurar Docker**
   - Configura autenticación para `gcr.io`

5. **🏗️ Construir imagen Docker**
   - Construye la imagen pasando el `GITHUB_TOKEN` como build arg
   - Etiqueta con el SHA del commit para versionado único

6. **🚀 Subir a Container Registry**
   - Push de la imagen a `gcr.io/raw-superapp/dbt-mcp-server`

7. **🌐 Desplegar a Cloud Run**
   - Despliega o actualiza el servicio con la nueva imagen
   - Configura todas las variables de entorno necesarias

8. **📊 Mostrar información**
   - Muestra la URL del servicio desplegado

## 🎯 Diferencias con el Workflow Original

| Aspecto | Original (ETL Jobs) | Nuevo (MCP Server) |
|---------|---------------------|-------------------|
| **Registry** | Artifact Registry | Container Registry (gcr.io) |
| **Tipo** | Cloud Run Jobs | Cloud Run Service |
| **Comando** | `gcloud run jobs deploy` | `gcloud run deploy` |
| **Ejecución** | `--execute-now` | Servicio persistente |
| **Credenciales** | Descarga de GCS | Embebidas en imagen |
| **Múltiples deploys** | 4 jobs diferentes | 1 servicio |
| **Timeout** | 900s (15 min) | 3600s (1 hora) |
| **Port** | No aplica | 8080 |

## 🧪 Pruebas Locales Antes de Push

Antes de hacer push y activar el workflow, puedes probar localmente:

```bash
# 1. Construir la imagen
docker build \
  --build-arg GITHUB_TOKEN=tu_token_aqui \
  -t dbt-mcp-server:test \
  .

# 2. Ejecutar localmente
docker run -p 8080:8080 \
  -e DBT_TOKEN=tu_dbt_token \
  -e DBT_PROD_ENV_ID=tu_env_id \
  dbt-mcp-server:test

# 3. Probar el servicio
curl http://localhost:8080/health
```

## 📝 Monitoreo del Workflow

### Ver logs en tiempo real

1. Ve a: https://github.com/yummysuperapp/bi-cloud-run-mcp-servers/actions
2. Haz clic en el workflow más reciente
3. Selecciona el job "deploy"
4. Verás cada paso con sus logs

### Verificar el despliegue

```bash
# Ver logs del servicio en Cloud Run
gcloud run services logs read dbt-mcp-server \
  --region=us-central1 \
  --project=raw-superapp \
  --limit=100

# Obtener URL del servicio
gcloud run services describe dbt-mcp-server \
  --region=us-central1 \
  --format="value(status.url)"
```

## 🚨 Troubleshooting

### Error: "Permission denied" al construir
- **Causa**: El GITHUB_TOKEN no tiene acceso al repo privado de dbt
- **Solución**: Verifica que el token tenga scope `repo`

### Error: "Authentication failed" con GCP
- **Causa**: El GCR_JSON_KEY es inválido o no tiene permisos
- **Solución**: Regenera la key del service account y actualiza el secret

### Error: "Image not found" al desplegar
- **Causa**: El push a gcr.io falló
- **Solución**: Verifica que Docker esté autenticado correctamente

### El servicio no responde después del deploy
- **Causa**: Variables de entorno faltantes o incorrectas
- **Solución**: Verifica todos los secrets en GitHub y los env vars en el workflow

## ✅ Checklist de Configuración

- [ ] Crear carpeta `.github/workflows/`
- [ ] Copiar archivo `deploy.yml`
- [ ] Configurar secret `GCR_JSON_KEY` en GitHub
- [ ] Configurar secret `GITHUB_TOKEN_PRIVATE` en GitHub
- [ ] Configurar secret `DBT_PROD_ENV_ID` en GitHub
- [ ] Configurar secret `DBT_USER_ID` en GitHub
- [ ] Configurar secret `DBT_TOKEN` en GitHub
- [ ] Hacer commit del workflow
- [ ] Push a main
- [ ] Verificar que el workflow se ejecute correctamente
- [ ] Probar el servicio desplegado

## 🎉 Resultado Esperado

Después de configurar todo correctamente:

1. Cada push a `main` activa el workflow automáticamente
2. El workflow construye y despliega la nueva versión
3. Cloud Run actualiza el servicio sin downtime
4. El servicio está disponible en la URL de Cloud Run
5. Puedes conectar Claude u otras apps MCP al servicio

## 📚 Referencias

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Workflow original](https://github.com/yummysuperapp/bi-cloud-run-bigquery-extract-load/blob/main/.github/workflows/deploy.yml)
