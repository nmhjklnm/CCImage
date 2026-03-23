#!/usr/bin/env python3
"""Generate sing-box JSON: TUN transparent path + DNS over proxy + no split for public egress."""
import json
import os

host = os.environ["PROXY_HOST"]
port = int(os.environ["PROXY_PORT"])
user = os.environ["PROXY_USER"]
password = os.environ["PROXY_PASS"]

cfg = {
    "log": {"level": "warn"},
    "dns": {
        "servers": [
            {
                "tag": "remote-dns",
                "address": "tls://1.1.1.1",
                "detour": "proxy",
            }
        ],
        "final": "remote-dns",
        "strategy": "ipv4_only",
    },
    "inbounds": [
        {
            "type": "tun",
            "tag": "tun-in",
            "interface_name": "tun0",
            "address": ["172.19.0.1/30"],
            "mtu": 9000,
            "auto_route": True,
            "strict_route": True,
            "stack": "system",
            "auto_redirect": True,
        }
    ],
    "outbounds": [
        {
            "type": "socks",
            "tag": "proxy",
            "server": host,
            "server_port": port,
            "version": "5",
            "username": user,
            "password": password,
        },
        {"type": "direct", "tag": "direct"},
    ],
    "route": {
        "rules": [
            {"action": "sniff"},
            {"protocol": "dns", "action": "hijack-dns"},
            {"ip_is_private": True, "outbound": "direct"},
        ],
        "final": "proxy",
        "auto_detect_interface": True,
    },
}

print(json.dumps(cfg, indent=2))
