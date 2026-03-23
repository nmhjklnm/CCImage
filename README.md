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
./ccimage setup     Configure proxy (interactive)
./ccimage create    Build the Docker image
./ccimage start     Start the container
./ccimage stop      Stop the container
./ccimage restart   Restart the container
./ccimage enter     Open a shell inside the container
./ccimage check     Run network diagnostics
./ccimage status    Show config and container state
./ccimage logs      Follow container logs
./ccimage destroy   Remove container and image
```

## Proxy Formats

`./ccimage setup` accepts:

| Format | Example |
|--------|---------|
| Share link | `ss://...`, `vmess://...`, `vless://...`, `trojan://...` |
| Compact | `1.2.3.4:1080:user:pass` |
| Compact (no auth) | `1.2.3.4:1080` |

## Networking

Container uses **macvlan** — gets its own IP directly on the physical network. Host VPN/TUN does not affect container traffic. Network settings are auto-detected during `./ccimage setup`.

## Requirements

- Linux + Docker / Docker Compose
- A working proxy

## License

MIT — see [LICENSE](LICENSE).
