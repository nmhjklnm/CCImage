ARG NODE_TAG=lts-bookworm
FROM node:${NODE_TAG}

ENV DEBIAN_FRONTEND=noninteractive

ARG SINGBOX_VERSION=1.11.4
ARG PROXY_HOST
ARG PROXY_PORT
ARG PROXY_USER
ARG PROXY_PASS

# Single layer: system packages + uv + sing-box
RUN set -eux; \
    if [ -n "${PROXY_HOST:-}" ] && [ -n "${PROXY_PORT:-}" ]; then \
      PROXY_URL="socks5h://${PROXY_USER:-}:${PROXY_PASS:-}@${PROXY_HOST}:${PROXY_PORT}"; \
      export http_proxy="$PROXY_URL" https_proxy="$PROXY_URL" \
             HTTP_PROXY="$PROXY_URL" HTTPS_PROXY="$PROXY_URL" ALL_PROXY="$PROXY_URL"; \
    fi; \
    CURL="curl ${PROXY_URL:+-x $PROXY_URL}"; \
    apt-get update && apt-get install -y --no-install-recommends \
      build-essential ca-certificates curl git iproute2 \
      locales nftables procps python3 python3-venv tzdata \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen en_US.UTF-8 \
    && corepack enable \
    && $CURL -LsSf https://astral.sh/uv/install.sh | UV_INSTALL_DIR=/usr/local sh \
    && ln -sf /usr/local/uv /usr/local/bin/uv \
    && ln -sf /usr/local/uvx /usr/local/bin/uvx \
    && ARCH="$(dpkg --print-architecture)" \
    && case "$ARCH" in amd64) SB_ARCH=amd64;; arm64) SB_ARCH=arm64;; *) echo "unsupported: $ARCH" >&2; exit 1;; esac \
    && $CURL -fsSL "https://github.com/SagerNet/sing-box/releases/download/v${SINGBOX_VERSION}/sing-box-${SINGBOX_VERSION}-linux-${SB_ARCH}.tar.gz" \
       | tar xzO "sing-box-${SINGBOX_VERSION}-linux-${SB_ARCH}/sing-box" > /usr/local/bin/sing-box \
    && chmod +x /usr/local/bin/sing-box

# Claude Code CLI
RUN set -eux; \
    if [ -n "${PROXY_HOST:-}" ] && [ -n "${PROXY_PORT:-}" ]; then \
      PROXY_URL="socks5h://${PROXY_USER:-}:${PROXY_PASS:-}@${PROXY_HOST}:${PROXY_PORT}"; \
    fi; \
    curl ${PROXY_URL:+-x "$PROXY_URL"} -fsSL https://claude.ai/install.sh | bash; \
    test -x /root/.local/bin/claude

ENV TZ=America/Los_Angeles \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    ACCEPT_LANGUAGE=en-US,en;q=0.9 \
    PATH="/root/.local/bin:${PATH}"

RUN echo 'export PATH="/root/.local/bin:$PATH"' >> /root/.bashrc

COPY lib/ /usr/local/lib/python3/dist-packages/ccimage/
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY ccimage-check /usr/local/bin/ccimage-check
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/ccimage-check

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["sleep", "infinity"]
