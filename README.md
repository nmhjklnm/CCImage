# CCImage

Docker image with **Node LTS**, **uv**, **sing-box TUN** and **Claude Code CLI**.

**Not an official Anthropic project.**

## Quick Start

```bash
git clone https://github.com/nmhjklnm/CCImage.git && cd CCImage
./ccimage setup     # paste proxy, network auto-detected
./ccimage create    # build image
./ccimage start     # start container
./ccimage enter     # open shell, run claude
```

## Commands

```
Lifecycle:
  ./ccimage setup               Configure proxy (interactive)
  ./ccimage create              Build the Docker image
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

Auto-detected during `./ccimage setup`:

| | Remote server (Linux) | Local laptop (Mac/Win) |
|--|----------------------|----------------------|
| **Network** | macvlan (own IP, isolated) | host (shares localhost) |
| **Port access** | `./ccimage port 6287` + SSH tunnel | Directly `localhost:6287` |
| **Host VPN interference** | No (macvlan bypasses) | N/A (you are the host) |

## Port Forwarding

**Remote server** — container has its own IP, need forwarding:

```bash
# On server: forward to localhost
./ccimage port 6287

# On laptop: SSH tunnel (your existing workflow)
ssh -L 6287:localhost:6287 -qN user@host
# → http://localhost:6287
```

**Local laptop** — host network, ports already on localhost. Nothing to do.

```bash
./ccimage port list       # see active forwarders
./ccimage port stop       # stop all
./ccimage port stop 3000  # stop one
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
