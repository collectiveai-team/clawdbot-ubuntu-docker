#!/bin/bash
set -e

# This script runs as root initially to fix permissions, then drops to nodeuser

if [ "$(id -u)" = "0" ]; then
    echo "========================================"
    echo "Clawdbot Ubuntu Container Startup"
    echo "========================================"
    
    # Fix ownership of .openclaw directory to nodeuser
    # This handles cases where volume mounts create files as wrong user
    echo ""
    echo "==> Fixing permissions..."
    chown -R nodeuser:nodeuser /home/nodeuser/.openclaw 2>/dev/null || true
    chmod -R u+rwx /home/nodeuser/.openclaw 2>/dev/null || true
    
    # Note: npm-global directory is already correctly owned from Docker build
    
    echo "Permissions fixed. Switching to nodeuser..."
    echo ""
    
    # Re-run this script as nodeuser
    exec gosu nodeuser "$0" "$@"
fi

# From here on, we run as nodeuser (UID 1000)

# Fix npm binary symlink if broken
# Fix npm binary symlink if broken (npm sometimes creates temp links)
NPM_BIN_DIR="/home/nodeuser/.npm-global/bin"
if [ ! -f "$NPM_BIN_DIR/openclaw" ]; then
    echo "==> Fixing OpenClaw binary symlink..."
    # If openclaw is missing but a temp link exists, start from there
    for link in "$NPM_BIN_DIR"/.openclaw*; do
        if [ -L "$link" ]; then
            ln -sf "$link" "$NPM_BIN_DIR/openclaw" 2>/dev/null || true
            break
        fi
    done
fi

# Update OpenClaw and tools to latest version
echo ""
echo "==> Checking for updates (Skipped for faster startup)..."
# npm update -g openclaw opencode-ai clawdhub undici 2>/dev/null || echo "Note: Update failed."
echo "To update manually run: docker exec --user nodeuser clawdbot-ubuntu npm update -g openclaw opencode-ai clawdhub"

# Verify installation
echo ""
echo "==> Verifying installation..."
if command -v openclaw >/dev/null 2>&1; then
    openclaw --version
else
    echo "ERROR: openclaw command not found in PATH"
    echo "PATH: $PATH"
    echo "Checking npm bin directory:"
    ls -la "$NPM_BIN_DIR" || echo "Directory not found"
    exit 1
fi

# Check if we have a config, if not run onboarding with auto-accept
if [ ! -f /home/nodeuser/.openclaw/config.json ]; then
    echo ""
    echo "==> First run detected. Running onboarding..."
    echo "Auto-accepting prompts (Yes for security, QuickStart for mode)..."
    # Send "Yes" for security prompt, then accept QuickStart default
    printf "Yes\n\n" | openclaw onboard || true
    
    # Configure gateway mode
    echo ""
    echo "==> Configuring gateway mode..."
    openclaw config set gateway.mode local || true
fi

# Check if auth-profiles.json exists for the main agent
AUTH_PROFILES_FILE="/home/nodeuser/.openclaw/agents/main/agent/auth-profiles.json"
if [ ! -f "$AUTH_PROFILES_FILE" ]; then
    echo ""
    echo "========================================"
    echo "  PROVIDER CONFIGURATION REQUIRED"
    echo "========================================"
    echo ""
    echo "No API key has been configured yet."
    echo "You need to add a provider (e.g., Anthropic, OpenAI) to use Clawdbot."
    echo ""
    echo "To configure your API provider, run this command:"
    echo ""
    echo "    docker exec -it clawdbot-ubuntu openclaw agents add main"
    echo ""
    echo "The gateway will start now, but requests will fail until configured."
    echo ""
    echo "========================================"
    echo ""
fi

# Start the gateway
echo ""
echo "==> Starting OpenClaw Gateway..."
echo "Ports: 18789 (API/Dashboard), 18790 (Bridge)"
echo ""

# Run gateway with configured settings
# Note: --bind uses modes (loopback|lan|tailnet|auto|custom), not IP addresses
#       Use "lan" to bind to all interfaces (accessible from outside container)
exec openclaw gateway run \
    --bind lan \
    --port "${OPENCLAW_GATEWAY_PORT:-18789}" \
    --token "${OPENCLAW_GATEWAY_TOKEN:-}" \
    "$@"
