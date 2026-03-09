FROM ghcr.io/rightnow-ai/openfang:latest

USER root

RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    nodejs \
    npm \
    chromium \
    curl \
    ca-certificates \
    git \
    build-essential \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

RUN python3 --version && \
    node --version && \
    npm --version && \
    chromium --version && \
    rustc --version && \
    cargo --version
