# CCImage Refactor: Configurable & Extensible

## Problem

Current codebase has repeated proxy URL construction (3x in Dockerfile), hardcoded values (DNS, MTU, TUN address, protocol), and only supports SOCKS5. Users must fill 4 separate env vars and cannot use share links.

## Goals

1. **Lazy user experience**: paste one `PROXY_URI` and go
2. **Configurable**: all sing-box parameters tunable via env vars with sane defaults
3. **Extensible**: support ss/vmess/vless/trojan share links
4. **Simplified code**: merge Dockerfile layers, single config engine
5. **Observable**: built-in network diagnostics (`ccimage-check`)
6. **Pre-built image**: publish to GHCR so most users skip `docker build`

## User Input

### Priority chain

1. `PROXY_URI` with `://` → parse as share link (ss/vmess/vless/trojan)
2. `PROXY_URI` without `://` → colon-split: `ip:port` (no auth) or `ip:port:user:pass` (SOCKS5)
3. `PROXY_HOST` + `PROXY_PORT` + optional `PROXY_USER`/`PROXY_PASS` → SOCKS5 (backward compat)
4. None → error

### Optional parameters (all have defaults)

| Env var | Default | Description |
|---------|---------|-------------|
| `DNS_SERVER` | `tls://1.1.1.1` | DNS server for sing-box |
| `TUN_ADDRESS` | `172.19.0.1/30` | TUN interface CIDR |
| `TUN_MTU` | `9000` | TUN MTU |
| `SINGBOX_ENABLE` | `1` | Enable sing-box TUN (0=env SOCKS only) |
| `DISABLE_IPV6` | `1` | Disable IPv6 via sysctl |
| `HEALTHCHECK` | `1` | Run connectivity check on startup |

## Architecture

### File structure

```
CCImage/
├── Dockerfile              # 2 RUN layers (system+tools / Claude CLI)
├── docker-compose.yml      # healthcheck + restart
├── entrypoint.sh           # slim launcher: call config.py, start sing-box, exec
├── .env.example            # all params documented
├── lib/
│   ├── config.py           # entry: read env → parse → generate → stdout
│   ├── protocols.py        # parse_uri() → ProxyConfig for each protocol
│   └── singbox.py          # ProxyConfig + env params → sing-box JSON
├── ccimage-check           # network diagnostics script
└── README.md
```

### Data model

```python
@dataclass
class ProxyConfig:
    type: str          # socks5 / vmess / vless / trojan / shadowsocks
    server: str
    port: int
    username: str = ""
    password: str = ""
    uuid: str = ""
    alter_id: int = 0
    security: str = ""
    method: str = ""
    tls: bool = False
    sni: str = ""
```

### Parse flow (config.py)

```
PROXY_URI set?
  ├─ contains "://" → protocols.parse_share_link(uri)
  ├─ colon-split 2 parts → ProxyConfig(type="socks5", no auth)
  └─ colon-split 4 parts → ProxyConfig(type="socks5", with auth)
else PROXY_HOST set?
  └─ ProxyConfig(type="socks5", from HOST/PORT/USER/PASS)
else → exit 1
```

### Protocol parsers (protocols.py)

- `ss://` — base64 decode `method:password@host:port`
- `vmess://` — base64 decode JSON body
- `vless://` — URL format `uuid@host:port?params`
- `trojan://` — URL format `password@host:port?params`

### Config generation (singbox.py)

`render(proxy: ProxyConfig, dns, tun_addr, mtu) → dict`

Generates sing-box JSON with:
- Outbound matching `proxy.type`
- DNS from `DNS_SERVER` env
- TUN from `TUN_ADDRESS`/`TUN_MTU` env
- Standard route rules (sniff, hijack-dns, private→direct, default→proxy)

## Network diagnostics (ccimage-check)

CLI command with checks:

| Check | Method | On failure |
|-------|--------|-----------|
| TUN status | Check tun0 interface + route | Check permissions, SINGBOX_ENABLE |
| DNS resolve | Resolve external domain through TUN | Check DNS_SERVER |
| DNS leak | Compare resolution paths | Check sing-box route rules |
| TCP connect | Connect google.com:443 | Check proxy address/auth |
| HTTP access | curl https://claude.ai | Check TLS/proxy config |

Also used by docker-compose healthcheck (TCP check only).

## Dockerfile changes

- Merge 3 RUN layers into 2 (system packages + tools in one, Claude CLI in another)
- Single proxy URL construction via build ARG
- Copy `lib/` directory instead of single script

## docker-compose.yml changes

- Add `healthcheck` using `ccimage-check` TCP mode
- Add `restart: unless-stopped`

## Pre-built image

- GitHub Actions workflow to build and push to GHCR on tag
- Users can `docker pull ghcr.io/nmhjklnm/ccimage:latest` and skip build entirely
- Dockerfile remains for custom builds

## Backward compatibility

- `PROXY_HOST/PORT/USER/PASS` still works exactly as before
- `SINGBOX_ENABLE=0` still falls back to env SOCKS
- New features are additive only
