#!/usr/bin/env bash
set -euo pipefail

SINGBOX_ENABLE="${SINGBOX_ENABLE:-1}"
DISABLE_IPV6="${DISABLE_IPV6:-1}"
HEALTHCHECK="${HEALTHCHECK:-1}"

unset ALL_PROXY HTTP_PROXY HTTPS_PROXY all_proxy http_proxy https_proxy \
      NO_PROXY no_proxy 2>/dev/null || true

if [[ "$DISABLE_IPV6" == "1" ]]; then
  sysctl -w net.ipv6.conf.all.disable_ipv6=1 2>/dev/null || true
  sysctl -w net.ipv6.conf.default.disable_ipv6=1 2>/dev/null || true
fi

_SINGBOX_PID=""

if [[ "$SINGBOX_ENABLE" == "1" ]]; then
  mkdir -p /etc/sing-box
  python3 -m ccimage > /etc/sing-box/config.json \
    || { echo "Failed to generate sing-box config" >&2; exit 1; }

  sing-box run -c /etc/sing-box/config.json &
  _SINGBOX_PID=$!

  for _ in $(seq 1 150); do
    ip -o link show tun0 2>/dev/null && break
    kill -0 "$_SINGBOX_PID" 2>/dev/null || { echo "sing-box exited before TUN came up" >&2; exit 1; }
    sleep 0.05
  done

  _net="${TUN_ADDRESS:-172.19.0.1/30}"
  _base="${_net%/*}"
  _prefix="${_base%.*}"
  _last="${_base##*.}"
  TUN_DNS="${_prefix}.$(( _last + 1 ))"
  printf 'nameserver %s\noptions ndots:0\n' "$TUN_DNS" > /etc/resolv.conf

  if [[ "$HEALTHCHECK" == "1" ]]; then
    echo "Running startup health check..."
    ccimage-check || echo "Warning: some checks failed (container will start anyway)" >&2
  fi

elif [[ "$SINGBOX_ENABLE" == "0" ]]; then
  if [[ -n "${PROXY_URI:-}" ]] && [[ "$PROXY_URI" != *"://"* ]]; then
    IFS=: read -r h p u pw <<< "$PROXY_URI"
    PROXY_URL="socks5h://${u:+$u:$pw@}$h:$p"
  elif [[ -n "${PROXY_HOST:-}" ]]; then
    PROXY_URL="socks5h://${PROXY_USER:+$PROXY_USER:$PROXY_PASS@}${PROXY_HOST}:${PROXY_PORT:-1080}"
  else
    echo "SINGBOX_ENABLE=0 but no SOCKS proxy configured" >&2
    exit 1
  fi
  export ALL_PROXY="$PROXY_URL" HTTP_PROXY="$PROXY_URL" HTTPS_PROXY="$PROXY_URL"
  export all_proxy="$PROXY_URL" http_proxy="$PROXY_URL" https_proxy="$PROXY_URL"
  export NO_PROXY="localhost,127.0.0.1,::1" no_proxy="localhost,127.0.0.1,::1"
  echo "SINGBOX_ENABLE=0: using env SOCKS only (not leak-safe)." >&2
else
  echo "SINGBOX_ENABLE must be 0 or 1" >&2
  exit 1
fi

_cleanup() {
  [[ -n "$_SINGBOX_PID" ]] && kill -TERM "$_SINGBOX_PID" 2>/dev/null && wait "$_SINGBOX_PID" 2>/dev/null || true
}
trap _cleanup EXIT INT TERM

exec "$@"
