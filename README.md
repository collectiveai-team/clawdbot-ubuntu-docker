# Clawdbot Ubuntu Docker Setup

Docker configuration based on Ubuntu 24.04 with Node 24 to run OpenClaw (Clawdbot).

## Features

- **Base:** Ubuntu 24.04 LTS
- **Node.js:** Version 24.x (latest)
- **Installation:** OpenClaw, OpenCode (opencode-ai), and ClawdHub via npm global
- **Coding Agents:** Support for coding agents via ClawdHub
- **Auto-update:** Skipped by default for speed (enable in start-clawdbot.sh)
- **User:** Runs as `nodeuser` (non-root)

## 🚀 Quick Start

```bash
# 1. Generate security token
openssl rand -hex 32

# 2. Create configuration file
cp .env.example .env

# 3. Edit .env and initialize your OPENCLAW_GATEWAY_TOKEN
vim .env

# 4. Create configuration directory
mkdir -p config

# 5. Build and start the container (first time)
docker compose up -d --build

# 6. View logs
docker compose logs -f clawdbot-ubuntu

# 7. Access dashboard
# http://localhost:18789
```

## 🔑 AI Provider Configuration (First Time)

The first time you start the container, you need to configure your AI provider (Anthropic, OpenAI, etc.). You have two options:

### Option 1: Configure from the running container

```bash
# With the container already started, run:
docker exec -it clawdbot-ubuntu openclaw agents add main
```

### Option 2: Interactive mode (recommended for first time)

```bash
# Stop the container if it is running
docker compose down

# Start in interactive mode (with TTY access)
docker compose run --service-ports clawdbot-ubuntu
```

This command will show you an interactive menu (TUI) where you can:
1. Select your provider (Anthropic, OpenAI, etc.)
2. Enter your API key
3. Configure additional preferences

After configuring, you can stop with `Ctrl+C` and restart normally with `docker compose up -d`.

## 📁 Directory Structure

```
clawdbot-ubuntu/
├── docker-compose.yml      # Main configuration
├── Dockerfile             # Ubuntu+Node24 image definition
├── start-clawdbot.sh      # Startup script with auto-update
├── .env.example          # Variable template
├── .env                  # Your configuration (DO NOT commit)
├── config/               # OpenClaw persistence
└── README.md            # This file
```

## 🔒 Security

### Implemented Measures

- ✅ **Ubuntu 24.04 LTS:** Updated and stable base system
- ✅ **Node 24:** Most recent LTS version
- ✅ **Non-root user:** Runs as `nodeuser` (UID 1000)
- ✅ **No new privileges:** Prevents privilege escalation
- ✅ **Read-only mounts:** System folders mounted as read-only
- ✅ **Resource limits:** Limits of 4GB RAM and 2 CPUs
- ✅ **Health check:** Automatic service health verification
- ✅ **Auto-update:** Always runs the latest version

### Access Levels

1. **Configuration (RW)** - Memory persistence and configuration
2. **Workspace (RW)** - Main workspace: `/home/YOUR_USER/Projects/clawdbot`
3. **Projects (RW)** - Access to all your projects: `/home/YOUR_USER/Projects`
4. **System (RO)** - Documents and Downloads read-only

## 📦 Mounted Volumes

### Active

- `./config:/home/nodeuser/.openclaw` - Bot configuration
- `/home/YOUR_USER/Projects/clawdbot:/home/nodeuser/.openclaw/workspace` - Workspace
- `/home/YOUR_USER/Projects:/mnt/projects` - All your projects
- `${HOME}/Documents:/mnt/documents:ro` - Documents (read-only)
- `${HOME}/Downloads:/mnt/downloads:ro` - Downloads (read-only)

### Optional (Commented)

- `${HOME}/dev:/mnt/dev:rw` - Development projects
- `${HOME}/repos:/mnt/repos:ro` - Git repositories
- `${HOME}/Clawdbot_Output:/mnt/output:rw` - Generated files
- `/var/run/docker.sock:/var/run/docker.sock:ro` - Docker socket
- `${HOME}/.ssh:/home/nodeuser/.ssh:ro` - SSH keys
- `${HOME}/.gitconfig:/home/nodeuser/.gitconfig:ro` - Git config
- `${HOME}/.npmrc:/home/nodeuser/.npmrc:ro` - NPM config

## 🖥️ TUI Client (Terminal User Interface)

The TUI client runs **outside** the container and connects to the containerized gateway.

### Setup TUI

```bash
# Add to your ~/.bashrc or ~/.zshrc:
export PATH="$HOME/bin:$PATH"

# Reload shell configuration:
source ~/.bashrc  # or source ~/.zshrc
```

### Using the TUI

```bash
# Launch TUI (connects to localhost:18789)
clawdbot-tui

# The TUI will automatically:
# - Check if the gateway is running
# - Load the token from .env file
# - Connect to the containerized gateway
```

### TUI Features

- **Interactive chat** with your AI agent
- **Session management** (create, switch, list sessions)
- **Tool execution** (file operations, shell commands)
- **Real-time streaming** responses
- **Command history** and auto-completion
- **Multi-agent support**

## 🤖 OpenCode & ClawdHub Setup

The container includes **OpenCode** and **ClawdHub** pre-installed for advanced coding agent capabilities.

### Configure Coding Agent

1. **Access the container as nodeuser:**

```bash
docker exec --user nodeuser -it clawdbot-ubuntu bash
```

2. **From the workspace (`/home/nodeuser/.openclaw/workspace`), run:**

```bash
cd /home/nodeuser/.openclaw/workspace
clawdhub install coding-agent
```

This will install and configure the coding agent in your workspace.

### Verify Installation

```bash
# Check OpenCode version
docker exec --user nodeuser clawdbot-ubuntu opencode --version

# Check ClawdHub version
docker exec --user nodeuser clawdbot-ubuntu clawdhub --version

# List installed agents
docker exec --user nodeuser clawdbot-ubuntu clawdhub list
```

### Using OpenCode

```bash
# Start OpenCode in interactive mode
docker exec --user nodeuser -it clawdbot-ubuntu opencode

# Or from inside the container
docker exec --user nodeuser -it clawdbot-ubuntu bash
cd /home/nodeuser/.openclaw/workspace
opencode
```

## 🔧 Useful Commands

### Service Management

```bash
# Build and start (first time)
docker-compose up -d --build

# Start only (if already built)
docker-compose up -d

# Stop
docker-compose down

# Restart
docker-compose restart

# View real-time logs
docker-compose logs -f clawdbot-ubuntu

# View status
docker-compose ps
```

### Accessing the Container

> ⚠️ **IMPORTANT:** The gateway runs as `nodeuser`. For configuration changes
> to take effect, always use `--user nodeuser` when running `docker exec` commands.
> If you run as root (default), the configuration is saved in `/root/.openclaw/`
> instead of `/home/nodeuser/.openclaw/` and the gateway will not see it.

```bash
# Interactive shell (as nodeuser - RECOMMENDED)
docker exec --user nodeuser -it clawdbot-ubuntu bash

# Run openclaw commands (as nodeuser)
docker exec --user nodeuser clawdbot-ubuntu openclaw <command>

# Examples:
docker exec --user nodeuser clawdbot-ubuntu openclaw models status
docker exec --user nodeuser clawdbot-ubuntu openclaw models set openai-codex/gpt-5.2
docker exec --user nodeuser clawdbot-ubuntu openclaw agents list

# As root (only for debugging - NOT for configuration)
docker exec --user root -it clawdbot-ubuntu bash
```

### CLI Usage

```bash
# Run clawdbot commands
docker-compose --profile cli run --rm clawdbot-cli <command>

# Examples:
docker-compose --profile cli run --rm clawdbot-cli onboard
docker-compose --profile cli run --rm clawdbot-cli status
docker-compose --profile cli run --rm clawdbot-cli channels list
```

### Manual Update

```bash
# The container already updates automatically on startup,
# but if you need to force an update:
docker exec --user nodeuser clawdbot-ubuntu npm update -g openclaw
docker restart clawdbot-ubuntu
```

### Configure Model

```bash
# View current model and authentication status
docker exec --user nodeuser clawdbot-ubuntu openclaw models status

# List available models
docker exec --user nodeuser clawdbot-ubuntu openclaw models list

# Change default model
docker exec --user nodeuser clawdbot-ubuntu openclaw models set openai-codex/gpt-5.2

# After changing the model, restart the gateway:
docker restart clawdbot-ubuntu
```

## 🛠️ Troubleshooting

### Permissions (EACCES)

If you see permission errors:

```bash
# Ensure correct ownership
sudo chown -R 1000:1000 /home/YOUR_USER/Projects/clawdbot-ubuntu/config
```

### Port Occupied

If port 18789 is in use:

```bash
# See which process is using it
sudo lsof -i :18789

# Kill the process or change the port in .env
```

### Rebuild Image

```bash
# Clean and rebuild from scratch
docker-compose down
docker rmi clawdbot-ubuntu:local
docker-compose up -d --build
```

### Model Not Applied (TUI shows incorrect model)

If you configured a model but the TUI still shows another one:

```bash
# The problem is that docker exec runs as root by default,
# saving the config in /root/.openclaw/ instead of /home/nodeuser/.openclaw/

# Verify what model nodeuser sees (the correct one):
docker exec --user nodeuser clawdbot-ubuntu openclaw models status

# If it shows the incorrect model, configure it as nodeuser:
docker exec --user nodeuser clawdbot-ubuntu openclaw models set <your-model>

# Restart the gateway to apply changes:
docker restart clawdbot-ubuntu
```

### View Installed Version

```bash
docker exec --user nodeuser clawdbot-ubuntu openclaw --version
docker exec --user nodeuser clawdbot-ubuntu node --version
```

## 📚 Differences from Official Setup

| Feature | Official Setup | Ubuntu Setup |
|----------------|---------------|--------------|
| **Base** | Node:22-bookworm | Ubuntu 24.04 |
| **Node** | 22.x | 24.x |
| **Installation** | From source (build) | npm global |
| **Update** | Manual | Auto (startup) |
| **Size** | ~500MB | ~700MB |
| **Tools** | Minimal | Full Ubuntu tools |

## 📖 Documentation

- [OpenClaw Docs](https://docs.openclaw.ai)
- [Ubuntu 24.04 LTS](https://ubuntu.com/download/server)
- [Node.js 24](https://nodejs.org/)
- [Docker Compose](https://docs.docker.com/compose/)

## ⚠️ Important Notes

1. **DO NOT** commit the `.env` file - it contains your secret token
2. The container updates automatically on startup (`npm update -g openclaw`)
3. The first execution may take longer due to the update
4. The workspace has full access to `/home/lio/Projects`
5. Exposed ports: 18789 (API), 18790 (Bridge)

## 🤝 Support

For OpenClaw support:
- GitHub Issues: https://github.com/openclaw/openclaw/issues
- Documentation: https://docs.openclaw.ai

---
**Version:** 1.0.0
**Date:** 2026-02-02
