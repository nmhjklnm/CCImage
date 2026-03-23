# CCImage

在 Docker 里提供 **Node LTS（Debian bookworm）**、**uv**、**sing-box** 与 **Claude Code CLI** 的安装与启动脚本；默认 **美国西海岸时区** 与 **en_US** 区域设置。适用于需要在 **Linux + 可访问中转 SOCKS5** 的环境下构建与运行 Claude Code 相关工具链的场景。

**非 Anthropic 官方项目**；Claude 与 Claude Code 为各自权利人的商标。

## 要求

- **Linux**（推荐；`docker-compose` 使用 `network_mode: host` + TUN）
- 构建与运行均需自备 **SOCKS5 代理**（`PROXY_*`），用于拉取 Debian 包、GitHub、Claude 安装脚本等
- Docker / Docker Compose

## 快速开始

```bash
cp .env.example .env
# 编辑 .env，填写 PROXY_HOST、PROXY_PORT、PROXY_USER、PROXY_PASS

docker compose build
docker compose run --rm ccimage bash
# 或长期驻留：docker compose up -d
```

容器内可执行 `claude`、`node`、`uv` 等（`PATH` 已包含 `~/.local/bin`）。

## 网络说明

- 默认 **`SINGBOX_ENABLE=1`**：启动 **sing-box TUN**，公网流量经 SOCKS 中转；会 **unset** `HTTP_PROXY`/`ALL_PROXY` 等，避免应用半直连。
- **`SINGBOX_ENABLE=0`**：仅设置 SOCKS 环境变量，**不保证**无直连泄漏，仅供调试。

上传仓库前请确认 **无真实代理地址、密码、主机名** 出现在提交中；`.env` 已列入 `.gitignore`。

## 安全提示

- `docker build` 传入的 `PROXY_PASS` 可能出现在镜像历史或构建日志中；生产环境请评估 **BuildKit secret** 或仅在可信环境构建。
- 定期轮换代理密码；勿在 issue/截图中泄露 `.env`。

## 许可证

MIT，见 [LICENSE](LICENSE)。
