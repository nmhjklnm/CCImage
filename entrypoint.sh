#!/usr/bin/env bash
set -euo pipefail

: "${PROXY_HOST:?Set PROXY_HOST (SOCKS5 transit)}"
: "${PROXY_PORT:?Set PROXY_PORT}"
: "${PROXY_USER:?Set PROXY_USER}"
: "${PROXY_PASS:?Set PROXY_PASS}"

SINGBOX_ENABLE="${SINGBOX_ENABLE:-1}"

unset ALL_PROXY HTTP_PROXY HTTPS_PROXY all_proxy http_proxy https_proxy || true
unset NO_PROXY no_proxy || true

sysctl -w net.ipv6.conf.all.disable_ipv6=1 2>/dev/null || true
sysctl -w net.ipv6.conf.default.disable_ipv6=1 2>/dev/null || true

_SINGBOX_PID=""

if [[ "${SINGBOX_ENABLE}" == "1" ]]; then
  mkdir -p /etc/sing-box
  python3 /usr/local/lib/render-singbox-config.py >/etc/sing-box/config.json
  sing-box run -c /etc/sing-box/config.json &
  _SINGBOX_PID=$!
  for _ in $(seq 1 150); do
    if ip -o link show 2>/dev/null | grep -qw tun; then
      break
    fi
    if ! kill -0 "${_SINGBOX_PID}" 2>/dev/null; then
      echo "sing-box exited before TUN came up" >&2
      exit 1
    fi
    sleep 0.05
  done
  printf 'nameserver 172.19.0.2\noptions ndots:0\n' >/etc/resolv.conf
elif [[ "${SINGBOX_ENABLE}" == "0" ]]; then
  PROXY_URL="socks5h://${PROXY_USER}:${PROXY_PASS}@${PROXY_HOST}:${PROXY_PORT}"
  export ALL_PROXY="${PROXY_URL}" HTTP_PROXY="${PROXY_URL}" HTTPS_PROXY="${PROXY_URL}"
  export all_proxy="${PROXY_URL}" http_proxy="${PROXY_URL}" https_proxy="${PROXY_URL}"
  export no_proxy="${NO_PROXY:-localhost,127.0.0.1,::1}" NO_PROXY="${NO_PROXY:-localhost,127.0.0.1,::1}"
  echo "SINGBOX_ENABLE=0: using env SOCKS only (not leak-safe)." >&2
else
  echo "SINGBOX_ENABLE must be 0 or 1" >&2
  exit 1
fi

_cleanup() {
  if [[ -n "${_SINGBOX_PID}" ]]; then
    kill -TERM "${_SINGBOX_PID}" 2>/dev/null || true
    wait "${_SINGBOX_PID}" 2>/dev/null || true
  fi
}
trap _cleanup EXIT INT TERM

exec "$@"
