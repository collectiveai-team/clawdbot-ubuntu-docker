FROM ubuntu:24.04

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive
ENV NODE_ENV=production
ENV TZ=America/New_York

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    ca-certificates \
    build-essential \
    python3 \
    python3-pip \
    vim \
    nano \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 24.x
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Verify Node installation
RUN node --version && npm --version

# Install pnpm globally (needed for some operations)
RUN npm install -g pnpm

# Create user and directories (UID 1001 - Ubuntu 24.04 already has 1000)
RUN useradd -m -s /bin/bash -u 1001 nodeuser \
    && mkdir -p /home/nodeuser/.openclaw \
    && mkdir -p /home/nodeuser/.openclaw/workspace \
    && chown -R nodeuser:nodeuser /home/nodeuser

# Setup npm prefix for local user installs
RUN mkdir -p /home/nodeuser/.npm-global \
    && chown -R nodeuser:nodeuser /home/nodeuser/.npm-global

# Switch to nodeuser for npm package installation
USER nodeuser
ENV NPM_CONFIG_PREFIX=/home/nodeuser/.npm-global
ENV PATH=/home/nodeuser/.npm-global/bin:$PATH

# Install OpenClaw, OpenCode, ClawdHub and dependencies locally
# undici is needed by clawdhub but missing in its deps
RUN npm install -g openclaw opencode-ai clawdhub undici

# Fix openclaw symlink if it points to a temp file or doesn't exist
RUN ln -sf ../lib/node_modules/openclaw/openclaw.mjs /home/nodeuser/.npm-global/bin/openclaw

# Set NODE_PATH so global modules can find each other (fixes clawdhub finding undici)
ENV NODE_PATH=/home/nodeuser/.npm-global/lib/node_modules

# Create startup script directory (switch back to root temporarily)
USER root
RUN mkdir -p /usr/local/bin

# Copy startup script with correct permissions
COPY --chmod=755 start-clawdbot.sh /usr/local/bin/start-clawdbot.sh
RUN chown nodeuser:nodeuser /usr/local/bin/start-clawdbot.sh

# Install gosu for dropping privileges
RUN apt-get update && apt-get install -y gosu && rm -rf /var/lib/apt/lists/*

# Set working directory (stay as root to fix permissions)
WORKDIR /home/nodeuser/.openclaw

# Expose ports
EXPOSE 18789 18790

# Use startup script as entrypoint (runs as root, drops to nodeuser)
ENTRYPOINT ["/usr/local/bin/start-clawdbot.sh"]
