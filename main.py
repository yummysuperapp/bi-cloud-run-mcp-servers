import asyncio
import os

from dbt_mcp.config.config import load_config
from dbt_mcp.mcp.server import create_dbt_mcp


def main() -> None:
    # Configurar puerto y host para SSE (Cloud Run usa PORT env var)
    port = os.environ.get('PORT', '8080')
    os.environ.setdefault('FASTMCP_HOST', '0.0.0.0')
    os.environ.setdefault('FASTMCP_PORT', port)
    
    config = load_config()
    asyncio.run(create_dbt_mcp(config)).run('sse')


if __name__ == "__main__":
    main()