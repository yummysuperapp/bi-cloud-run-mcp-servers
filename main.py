import asyncio
import os

from dbt_mcp.config.config import load_config
from dbt_mcp.mcp.server import create_dbt_mcp


def main() -> None:
    # Configurar puerto y host para HTTP (Cloud Run usa PORT env var)
    port = os.environ.get('PORT', '8080')
    os.environ.setdefault('FASTMCP_HOST', '0.0.0.0')
    os.environ.setdefault('FASTMCP_PORT', port)
    
    # Validar que existe token de autenticación
    auth_token = os.environ.get('MCP_AUTH_TOKEN')
    if not auth_token:
        raise ValueError("MCP_AUTH_TOKEN environment variable must be set for secure HTTP transport")
    
    config = load_config()
    # Usar HTTP transport seguro en lugar de SSE
    asyncio.run(create_dbt_mcp(config)).run('http')


if __name__ == "__main__":
    main()
