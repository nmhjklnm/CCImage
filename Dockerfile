# 基于官方 Node 镜像（Node/npm 已由上游构建好，换版本只改 ARG）
# 默认 lts-bookworm；钉死主版本：--build-arg NODE_TAG=22-bookworm
ARG NODE_TAG=lts-bookworm
FROM node:${NODE_TAG}

ENV DEBIAN_FRONTEND=noninteractive

ARG SINGBOX_VERSION=1.11.4

# 构建期必选：经 SOCKS5 访问 Debian 源 / GitHub / claude.ai / GCS（勿在镜像中硬编码密码）
# docker compose build（从 .env 注入）或:
#   docker build --build-arg PROXY_HOST=... --build-arg PROXY_PORT=... --build-arg PROXY_USER=... --build-arg PROXY_PASS=...
ARG PROXY_HOST
ARG PROXY_PORT
ARG PROXY_USER
ARG PROXY_PASS

RUN set -eux; \
    test -n "${PROXY_HOST}" && test -n "${PROXY_PORT}" && test -n "${PROXY_USER}" && test -n "${PROXY_PASS}" \
      || { echo "缺少必选构建参数 PROXY_HOST / PROXY_PORT / PROXY_USER / PROXY_PASS" >&2; exit 1; }; \
    PROXY_URL="socks5h://${PROXY_USER}:${PROXY_PASS}@${PROXY_HOST}:${PROXY_PORT}"; \
    export http_proxy="$PROXY_URL" https_proxy="$PROXY_URL" HTTP_PROXY="$PROXY_URL" HTTPS_PROXY="$PROXY_URL" ALL_PROXY="$PROXY_URL"; \
    apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    git \
    iproute2 \
    locales \
    nftables \
    procps \
    python3 \
    python3-venv \
    tzdata \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen en_US.UTF-8 \
    && corepack enable

RUN set -eux; \
    PROXY_URL="socks5h://${PROXY_USER}:${PROXY_PASS}@${PROXY_HOST}:${PROXY_PORT}"; \
    curl -x "$PROXY_URL" -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local sh; \
    ARCH="$(dpkg --print-architecture)"; \
    case "$ARCH" in \
      amd64) SB_ARCH=amd64 ;; \
      arm64) SB_ARCH=arm64 ;; \
      *) echo "unsupported arch: $ARCH" >&2; exit 1 ;; \
    esac; \
    curl -x "$PROXY_URL" -fsSL "https://github.com/SagerNet/sing-box/releases/download/v${SINGBOX_VERSION}/sing-box-${SINGBOX_VERSION}-linux-${SB_ARCH}.tar.gz" \
    | tar xzO "sing-box-${SINGBOX_VERSION}-linux-${SB_ARCH}/sing-box" > /usr/local/bin/sing-box \
    && chmod +x /usr/local/bin/sing-box \
    && ln -sf /usr/local/uv /usr/local/bin/uv \
    && ln -sf /usr/local/uvx /usr/local/bin/uvx

# Claude Code CLI（官方脚本装到 /root/.local/bin）
RUN set -eux; \
    PROXY_URL="socks5h://${PROXY_USER}:${PROXY_PASS}@${PROXY_HOST}:${PROXY_PORT}"; \
    curl -x "$PROXY_URL" -fsSL https://claude.ai/install.sh | bash; \
    test -x /root/.local/bin/claude

ENV TZ=America/Los_Angeles
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
ENV ACCEPT_LANGUAGE=en-US,en;q=0.9
ENV PATH="/root/.local/bin:${PATH}"

RUN echo 'export PATH="/root/.local/bin:$PATH"' >> /root/.bashrc

COPY render-singbox-config.py /usr/local/lib/render-singbox-config.py
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/lib/render-singbox-config.py

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["sleep", "infinity"]
