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
    'mkdir -p /data' \
    'cat > /data/config.toml <<EOF' \
    '[api]' \
    'listen_addr = "0.0.0.0:50051"' \
    '' \
    '[llm]' \
    'provider = "${OPENFANG_LLM_PROVIDER:-gemini}"' \
    'model = "${OPENFANG_LLM_MODEL:-gemini-3-flash-preview}"' \
    'api_key_env = "${OPENFANG_LLM_API_KEY_ENV:-GEMINI_API_KEY}"' \
    'EOF' \
    'exec openfang start --config /data/config.toml' \
    > /usr/local/bin/start-openfang.sh && \
    chmod +x /usr/local/bin/start-openfang.sh

ENV OPENFANG_HOME=/data
WORKDIR /app

RUN mkdir -p /data /app && \
    python3 --version && \
    node --version && \
    npm --version && \
    chromium --version && \
    rustc --version && \
    cargo --version && \
    openfang --version

EXPOSE 50051

CMD ["/usr/local/bin/start-openfang.sh"]
