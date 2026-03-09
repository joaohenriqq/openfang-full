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

RUN printf '%s\n' \
    '#!/bin/sh' \
    'set -eu' \
    'mkdir -p /data /workspace' \
    'cat > /data/config.toml <<EOF' \
    'api_listen = "0.0.0.0:50051"' \
    '' \
    '[default_model]' \
    'provider = "gemini"' \
    'model = "gemini-2.5-flash"' \
    'api_key_env = "GEMINI_API_KEY"' \
    '' \
    '[[mcp_servers]]' \
    'name = "meta-ads"' \
    'url = "http://ia_meta-ads-mcp:8080/mcp"' \
    '' \
    '[[mcp_servers]]' \
    'name = "notion-mcp"' \
    'url = "https://mcp.notion.com/mcp"' \
    '' \
    '[[mcp_servers]]' \
    'name = "kie-mcp"' \
    'url = "http://ia_mcp-kie_ia_mcp-kie-ai:8081/mcp"' \
    '' \
    '[[mcp_servers]]' \
    'name = "runware-mcp"' \
    'url = "http://ia_mcp-runware:8081/sse"' \
    '' \
    '[[mcp_servers]]' \
    'name = "filesystem"' \
    'timeout_secs = 30' \
    '[mcp_servers.transport]' \
    'type = "stdio"' \
    'command = "npx"' \
    'args = ["-y", "@modelcontextprotocol/server-filesystem", "/workspace"]' \
    'EOF' \
    'exec openfang start --config /data/config.toml' \
    > /usr/local/bin/start-openfang.sh && \
    chmod +x /usr/local/bin/start-openfang.sh

ENV OPENFANG_HOME=/data
WORKDIR /app

RUN mkdir -p /data /app /workspace && \
    python3 --version && \
    node --version && \
    npm --version && \
    chromium --version && \
    yt-dlp --version && \
    ffmpeg -version | head -n 1 && \
    sudo --version | head -n 1 && \
    rustc --version && \
    cargo --version && \
    openfang --version

EXPOSE 50051

CMD ["/usr/local/bin/start-openfang.sh"]
