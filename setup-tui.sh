#!/bin/bash
set -e

echo "========================================"
echo "Setting up TUI Client for OpenClaw"
echo "========================================"

PROJECT_DIR="/home/lio/Projects/clawdbot"
TUI_DIR="/home/lio/Projects/clawdbot-tui"

# Create TUI directory
mkdir -p "$TUI_DIR"

# Check if we have the source code
if [ ! -f "$PROJECT_DIR/package.json" ]; then
    echo "ERROR: OpenClaw source not found at $PROJECT_DIR"
    echo "Please ensure the repository is cloned"
    exit 1
fi

cd "$PROJECT_DIR"

# Check if already built
if [ ! -d "$PROJECT_DIR/dist" ]; then
    echo ""
    echo "==> Building OpenClaw (this may take a few minutes)..."
    
    # Check for pnpm
    if ! command -v pnpm &> /dev/null; then
        echo "Installing pnpm..."
        npm install -g pnpm
    fi
    
    # Install dependencies
    echo "Installing dependencies..."
    pnpm install
    
    # Build the project
    echo "Building project..."
    pnpm build
else
    echo ""
    echo "==> OpenClaw already built, skipping build step"
fi

# Create TUI launcher script
cat > "$TUI_DIR/clawdbot-tui" << 'SCRIPT'
#!/bin/bash
# TUI Client Launcher for OpenClaw
# This connects to the containerized gateway

PROJECT_DIR="/home/lio/Projects/clawdbot"
DEFAULT_GATEWAY="http://localhost:18789"

# Source the environment file if it exists
if [ -f "/home/lio/Projects/clawdbot-ubuntu/.env" ]; then
    export $(grep -v '^#' /home/lio/Projects/clawdbot-ubuntu/.env | xargs)
fi

# Get token from environment or prompt
TOKEN="${OPENCLAW_GATEWAY_TOKEN:-}"
if [ -z "$TOKEN" ]; then
    echo "Warning: OPENCLAW_GATEWAY_TOKEN not set"
    echo "The TUI may not be able to connect to the gateway"
fi

cd "$PROJECT_DIR"

# Run the TUI
echo "Starting OpenClaw TUI..."
echo "Connecting to: $DEFAULT_GATEWAY"
echo ""

exec node scripts/run-node.mjs tui "$@"
SCRIPT

chmod +x "$TUI_DIR/clawdbot-tui"

# Create symlink in /usr/local/bin for easy access
if [ -w "/usr/local/bin" ]; then
    sudo ln -sf "$TUI_DIR/clawdbot-tui" /usr/local/bin/clawdbot-tui
    echo ""
    echo "✓ Created symlink: /usr/local/bin/clawdbot-tui"
else
    echo ""
    echo "✓ TUI launcher created at: $TUI_DIR/clawdbot-tui"
    echo "  Add to your PATH: export PATH=\"$TUI_DIR:\$PATH\""
fi

# Create desktop entry (optional)
cat > "$TUI_DIR/clawdbot-tui.desktop" << EOF
[Desktop Entry]
Name=Clawdbot TUI
Comment=Terminal UI for OpenClaw Gateway
Exec=$TUI_DIR/clawdbot-tui
Type=Application
Terminal=true
Categories=Development;
EOF

echo ""
echo "========================================"
echo "TUI Client Setup Complete!"
echo "========================================"
echo ""
echo "Usage:"
echo "  clawdbot-tui              # Launch TUI (connects to localhost:18789)"
echo ""
echo "Make sure the gateway is running:"
echo "  cd /home/lio/Projects/clawdbot-ubuntu"
echo "  docker compose up -d"
echo ""
echo "Get your gateway token from:"
echo "  /home/lio/Projects/clawdbot-ubuntu/.env"
echo ""
