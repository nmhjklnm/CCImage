#!/usr/bin/env python3
"""CCImage config entry point.

Read proxy settings from environment, generate sing-box JSON to stdout.
"""

from __future__ import annotations

import os
import sys

from .protocols import ProxyConfig, parse
from .singbox import render_json


def _proxy_from_env() -> ProxyConfig:
    """Resolve proxy config from environment variables."""
    uri = os.environ.get("PROXY_URI", "").strip()
    if uri:
        return parse(uri)

    host = os.environ.get("PROXY_HOST", "").strip()
    if not host:
        print(
            "Error: set PROXY_URI or PROXY_HOST+PROXY_PORT to configure the proxy.",
            file=sys.stderr,
        )
        sys.exit(1)

    port = int(os.environ.get("PROXY_PORT", "1080"))
    user = os.environ.get("PROXY_USER", "")
    passwd = os.environ.get("PROXY_PASS", "")
    return ProxyConfig(
        type="socks5", server=host, port=port, username=user, password=passwd
    )


def main() -> None:
    proxy = _proxy_from_env()
    dns = os.environ.get("DNS_SERVER", "tls://1.1.1.1")
    tun_addr = os.environ.get("TUN_ADDRESS", "172.19.0.1/30")
    tun_mtu = int(os.environ.get("TUN_MTU", "9000"))
    print(render_json(proxy, dns_server=dns, tun_address=tun_addr, tun_mtu=tun_mtu))


if __name__ == "__main__":
    main()
