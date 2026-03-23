# CCImage

Docker image with **Node LTS**, **uv**, **sing-box TUN** and **Claude Code CLI**.

**Not an official Anthropic project.**

## Quick Start

```bash
git clone https://github.com/nmhjklnm/CCImage.git && cd CCImage
./ccimage setup     # paste proxy, network auto-detected
./ccimage create    # pull image
./ccimage start     # start container
./ccimage enter     # open shell, run claude
```

## Commands

```
Lifecycle:
  ./ccimage setup               Configure proxy (interactive)
  ./ccimage create              Pull the Docker image
  ./ccimage start               Start the container
  ./ccimage stop                Stop the container
  ./ccimage restart             Restart the container
  ./ccimage destroy             Remove container and image

Use:
  ./ccimage enter               Open a shell (run claude inside)
  ./ccimage port <port>         Forward localhost:port to container
  ./ccimage port list           List active port forwarders
  ./ccimage port stop [port]    Stop port forwarder(s)

Diagnostics:
  ./ccimage check               Network check (inside container)
  ./ccimage verify              Verify outbound isolation (from host)
  ./ccimage status              Show config, state, and ports
  ./ccimage logs                Follow container logs
```

## Two Deployment Modes

Auto-detected during `./ccimage setup`. Both modes use **isolated network namespaces** — container TUN never affects the host, host VPN never affects the container.

| | Remote server (Linux) | Local laptop (Mac/Win) |
|--|----------------------|----------------------|
| **Network** | macvlan (own IP on physical LAN) | bridge (Docker internal network) |
| **Isolation** | Full — bypasses host network stack | Full — own namespace |
| **Host VPN affects container** | No | No |
| **Port access** | `./ccimage port` + SSH tunnel | `./ccimage port` |

## Port Forwarding

```bash
./ccimage port 6287       # forward localhost:6287 → container:6287
./ccimage port 3000       # another port
./ccimage port list       # see active forwarders
./ccimage port stop       # stop all
./ccimage port stop 3000  # stop one
```

**Remote server** — add SSH tunnel from your laptop:

```bash
ssh -L 6287:localhost:6287 -qN user@host
# → http://localhost:6287 on your laptop
```

## Verifying Outbound

```bash
# Inside container — TUN, DNS, leak, connectivity
./ccimage check

# From host (remote only) — proves macvlan isolation
./ccimage verify
```

`./ccimage verify` checks:

| Check | Proves |
|-------|--------|
| Exit IP comparison | Container and host exit through different IPs |
| MAC address | Container has own MAC (macvlan active) |
| Traffic path | Routes through physical gateway, not Docker bridge |
| Packet capture | tcpdump sees container packets on physical NIC |

## Proxy Formats

`./ccimage setup` accepts:

| Format | Example |
|--------|---------|
| Share link | `ss://...`, `vmess://...`, `vless://...`, `trojan://...` |
| Compact | `1.2.3.4:1080:user:pass` |
| Compact (no auth) | `1.2.3.4:1080` |

## Requirements

- Docker / Docker Compose (Linux, macOS, or Windows)
- Remote server: socat (`apt install socat`) for port forwarding
- A working proxy

## License

MIT — see [LICENSE](LICENSE).
