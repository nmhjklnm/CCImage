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

## Port Forwarding

Container uses macvlan (own IP, isolated from host). To access container ports from your laptop:

```bash
# Step 1: forward container port to host localhost
./ccimage port 6287

# Step 2: SSH tunnel from laptop (your existing workflow)
ssh -L 6287:localhost:6287 -qN user@host
# → http://localhost:6287 on your laptop
```

Multiple ports:

```bash
./ccimage port 3000
./ccimage port 8080
./ccimage port list       # see all active
./ccimage port stop       # stop all
./ccimage port stop 3000  # stop one
```

## Verifying Outbound Isolation

Container traffic must go through your proxy, not the host's VPN. Two levels of verification:

```bash
# 1. Inside container — checks TUN, DNS, leak, connectivity
./ccimage check

# 2. From host — proves macvlan isolation with packet-level evidence
./ccimage verify
```

`./ccimage verify` performs 4 checks from the **host side**:

| Check | What it proves |
|-------|---------------|
| **Exit IP comparison** | Container and host have different exit IPs → different network paths |
| **MAC address** | Container has its own MAC → macvlan active, not sharing host NIC |
| **Traffic path** | Container routes through physical gateway, not Docker bridge |
| **Packet capture** | tcpdump on physical NIC sees container packets → bypasses host stack |

If all 4 pass, container outbound is **provably isolated** from the host.

## Proxy Formats

`./ccimage setup` accepts:

| Format | Example |
|--------|---------|
| Share link | `ss://...`, `vmess://...`, `vless://...`, `trojan://...` |
| Compact | `1.2.3.4:1080:user:pass` |
| Compact (no auth) | `1.2.3.4:1080` |

## Requirements

- Linux + Docker / Docker Compose + socat (`apt install socat`)
- A working proxy

## License

MIT — see [LICENSE](LICENSE).
