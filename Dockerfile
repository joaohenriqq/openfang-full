FROM rust:1.77-bookworm AS builder

RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    ca-certificates \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
RUN git clone https://github.com/RightNow-AI/openfang.git .
RUN cargo build --release -p openfang-cli


FROM rust:1.77-bookworm

RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    nodejs \
    npm \
    chromium \
    yt-dlp \
    ffmpeg \
    sudo \
    curl \
    ca-certificates \
    git \
    sqlite3 \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /build/target/release/openfang /usr/local/bin/openfang

RUN ln -sf /usr/bin/chromium /usr/local/bin/chromium-browser || true

ENV OPENFANG_HOME=/data
ENV HOME=/root
ENV MCP_REMOTE_CONFIG_DIR=/data/mcp-auth

RUN printf '%s\n' \
    '#!/bin/sh' \
    'set -eu' \
    'mkdir -p /data /data/mcp-auth /workspace' \
    'cat > /data/config.toml <<EOF' \
    'api_listen = "0.0.0.0:50051"' \
    '' \
    '[default_model]' \
    'provider = "gemini"' \
    'model = "gemini-2.5-flash"' \
    'api_key_env = "GEMINI_API_KEY"' \
    '' \
    '[[mcp_servers]]' \
    'name = "filesystem"' \
    'timeout_secs = 30' \
    '' \
    '[mcp_servers.transport]' \
    'type = "stdio"' \
    'command = "npx"' \
    'args = ["-y", "@modelcontextprotocol/server-filesystem", "/workspace"]' \
    '' \
    '[[mcp_servers]]' \
    'name = "meta-ads"' \
    'timeout_secs = 60' \
    'env = ["HOME", "MCP_REMOTE_CONFIG_DIR"]' \
    '' \
    '[mcp_servers.transport]' \
    'type = "stdio"' \
    'command = "npx"' \
    'args = ["-y", "mcp-remote@latest", "https://ads-mcp.imperiolabs.com.br/mcp", "--transport", "http-only"]' \
    '' \
    '[[mcp_servers]]' \
    'name = "notion-mcp"' \
    'timeout_secs = 60' \
    'env = ["HOME", "MCP_REMOTE_CONFIG_DIR"]' \
    '' \
    '[mcp_servers.transport]' \
    'type = "stdio"' \
    'command = "npx"' \
    'args = ["-y", "mcp-remote@latest", "https://mcp.notion.com/mcp", "--transport", "http-first"]' \
    '' \
    '[[mcp_servers]]' \
    'name = "n8n-mcp-vps"' \
    'timeout_secs = 150' \
    'env = ["HOME", "MCP_REMOTE_CONFIG_DIR", "N8N_MCP_AUTH_HEADER"]' \
    '' \
    '[mcp_servers.transport]' \
    'type = "stdio"' \
    'command = "npx"' \
    'args = ["-y", "mcp-remote@latest", "https://ia-mcp-n8n-1.y7xhql.easypanel.host/mcp", "--header", "Authorization:${N8N_MCP_AUTH_HEADER}", "--transport", "http-only"]' \
    '' \
    '[[mcp_servers]]' \
    'name = "context7"' \
    'timeout_secs = 60' \
    'env = ["HOME", "MCP_REMOTE_CONFIG_DIR", "CONTEXT7_API_KEY"]' \
    '' \
    '[mcp_servers.transport]' \
    'type = "stdio"' \
    'command = "npx"' \
    'args = ["-y", "mcp-remote@latest", "https://mcp.context7.com/mcp", "--header", "CONTEXT7_API_KEY:${CONTEXT7_API_KEY}", "--transport", "http-only"]' \
    '' \
    '[[mcp_servers]]' \
    'name = "kie-mcp"' \
    'timeout_secs = 60' \
    'env = ["HOME", "MCP_REMOTE_CONFIG_DIR"]' \
    '' \
    '[mcp_servers.transport]' \
    'type = "stdio"' \
    'command = "npx"' \
    'args = ["-y", "mcp-remote@latest", "http://ia_mcp-kie_ia_mcp-kie-ai:8081/mcp", "--allow-http", "--transport", "http-first"]' \
    '' \
    '[[mcp_servers]]' \
    'name = "runware-mcp"' \
    'timeout_secs = 60' \
    'env = ["HOME", "MCP_REMOTE_CONFIG_DIR"]' \
    '' \
    '[mcp_servers.transport]' \
    'type = "stdio"' \
    'command = "npx"' \
    'args = ["-y", "mcp-remote@latest", "http://ia_mcp-runware:8081/sse", "--allow-http", "--transport", "sse-only"]' \
    'EOF' \
    'exec openfang start --config /data/config.toml' \
    > /usr/local/bin/start-openfang.sh && \
    chmod +x /usr/local/bin/start-openfang.sh

WORKDIR /app

EXPOSE 50051

CMD ["/usr/local/bin/start-openfang.sh"]
