# 🔧 Solución: Credenciales de BigQuery en el Contenedor

## ❌ El Problema

Según las pruebas del MCP, había un error al ejecutar consultas dbt:

```
Database Error
expected str, bytes or os.PathLike object, not NoneType
```

Este error indicaba que **las credenciales de BigQuery no estaban disponibles dentro del contenedor Docker**.

## 🔍 Análisis

El problema tenía dos partes:

### 1. Archivo de Credenciales No Copiado
El `Dockerfile` **NO** estaba copiando el archivo `yummy-development.json` al contenedor.

### 2. Profiles.yml Sin Keyfile
El `profiles.yml` no especificaba la ruta del archivo de credenciales:

```yaml
# ❌ ANTES - Sin keyfile
default:
  outputs:
    dev:
      dataset: dbt_rides
      method: service-account
      project: production-yummy
      threads: 4
      type: bigquery
      # Comentario diciendo que usaría GOOGLE_APPLICATION_CREDENTIALS
  target: dev
```

## ✅ La Solución

### 1. Actualizar Dockerfile

Agregamos estos pasos al `Dockerfile`:

```dockerfile
# CRITICAL: Copy BigQuery credentials for dbt
# This file contains the service account credentials for accessing BigQuery
RUN mkdir -p /app/credentials
COPY yummy-development.json /app/credentials/yummy-development.json
```

**Ubicación**: Después de copiar `profiles.yml` y antes del `entrypoint.sh`

### 2. Actualizar profiles.yml

Especificamos explícitamente la ruta del keyfile:

```yaml
# ✅ DESPUÉS - Con keyfile explícito
default:
  outputs:
    dev:
      dataset: dbt_rides
      keyfile: /app/credentials/yummy-development.json  # ← Agregado
      method: service-account
      project: production-yummy
      threads: 4
      type: bigquery
  target: dev
```

## 🏗️ Arquitectura de Service Accounts

Este proyecto usa **DOS** service accounts para separar responsabilidades:

### 1. raw-superapp (Deployment/CI/CD)
```
Secret: GCR_JSON_KEY_RAW_SUPERAPP
Proyecto: raw-superapp
Service Account: kustomer@raw-superapp.iam.gserviceaccount.com
```

**Responsabilidades:**
- ✅ Construir imágenes Docker
- ✅ Push a Artifact Registry
- ✅ Desplegar a Cloud Run
- ✅ Gestionar infraestructura

### 2. yummy-development (dbt/BigQuery)
```
Secret: GCR_JSON_KEY
Proyecto: yummy-development
Service Account: dbt-dev@yummy-development.iam.gserviceaccount.com
Archivo: yummy-development.json
```

**Responsabilidades:**
- ✅ Leer/escribir en BigQuery
- ✅ Ejecutar queries dbt
- ✅ Acceso a datasets en `production-yummy`

## 📁 Estructura de Archivos en el Contenedor

```
/app/
├── credentials/
│   └── yummy-development.json        ← Credenciales de BigQuery
├── bi-dbt-bigquery-models/
│   ├── dbt_env/                      ← Virtual environment de dbt
│   ├── models/                       ← Modelos dbt
│   └── ...
└── dbt-mcp/
    └── ...

/root/.dbt/
└── profiles.yml                      ← Configuración de dbt
```

## 🔐 Seguridad

### Protección en Git
El archivo `yummy-development.json` está protegido por `.gitignore`:

```gitignore
# Archivos de credenciales nunca se suben a Git
service-account.json
yummy-development.json
production-yummy.json
*.json
```

### En el Contenedor Docker
- ✅ El archivo se copia durante el **build** de la imagen
- ✅ Se almacena en `/app/credentials/` dentro del contenedor
- ✅ Solo accesible por el proceso de dbt dentro del contenedor
- ✅ No se expone en ningún endpoint HTTP

## 🧪 Cómo Probar

Después del deployment, puedes probar que las credenciales funcionan:

### 1. Usando el MCP desde Claude

```
Dame el total de viajes completados de hoy
```

Debería usar la métrica `trips_completed` del dbt Semantic Layer sin errores.

### 2. Verificar en los Logs de Cloud Run

```bash
gcloud run services logs read dbt-mcp-server \
  --region=us-central1 \
  --project=raw-superapp \
  --limit=50
```

Busca líneas como:
```
✓ Connection test successful
✓ Successfully queried BigQuery
```

## 📊 Flujo de Datos

```
Usuario (Claude)
    ↓
MCP Server (Cloud Run)
    ↓
dbt Semantic Layer
    ↓
dbt CLI (usa yummy-development.json)
    ↓
BigQuery (production-yummy)
```

## ⚠️ Troubleshooting

### Error: "Database Error: expected str, bytes or os.PathLike object"

**Causa**: El archivo de credenciales no está en el contenedor o `profiles.yml` no lo encuentra.

**Solución**: Verificar que:
1. ✅ `yummy-development.json` existe localmente
2. ✅ `Dockerfile` copia el archivo
3. ✅ `profiles.yml` tiene el `keyfile` correcto
4. ✅ El path es `/app/credentials/yummy-development.json`

### Error: "Permission denied"

**Causa**: El service account no tiene permisos en BigQuery.

**Solución**: Verificar roles en GCP Console:
```bash
gcloud projects get-iam-policy production-yummy \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:dbt-dev@yummy-development.iam.gserviceaccount.com"
```

Roles necesarios:
- `roles/bigquery.dataViewer`
- `roles/bigquery.jobUser`

### Error: "Project not found"

**Causa**: El proyecto en `profiles.yml` no coincide con el que tiene acceso el service account.

**Solución**: Verificar que en `profiles.yml`:
```yaml
project: production-yummy  # ← Debe ser el proyecto correcto
```

## ✅ Checklist de Configuración

- [x] `yummy-development.json` existe localmente
- [x] `yummy-development.json` está en `.gitignore`
- [x] `Dockerfile` copia el archivo a `/app/credentials/`
- [x] `profiles.yml` especifica `keyfile: /app/credentials/yummy-development.json`
- [x] Service account tiene permisos en BigQuery
- [x] `profiles.yml` apunta al proyecto correcto (`production-yummy`)
- [x] Workflow usa `GCR_JSON_KEY_RAW_SUPERAPP` para deployment
- [x] Workflow usa `GCR_JSON_KEY` para validación

## 📚 Referencias

- [dbt BigQuery Configuration](https://docs.getdbt.com/reference/warehouse-setups/bigquery-setup)
- [Google Cloud Service Accounts](https://cloud.google.com/iam/docs/service-accounts)
- [Docker COPY instruction](https://docs.docker.com/engine/reference/builder/#copy)
