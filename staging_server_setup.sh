#!/bin/bash

# Staging Server Setup Script
# Sets up a fresh Ubuntu VPS as a multi-project staging server.
# Includes: Docker, Git, GitHub CLI, Go, Node.js, Caddy, Postgres, Redis,
# fail2ban, unattended upgrades, and a non-root deploy user.
#
# Usage: curl -sSL <raw_url> | bash
#   or:  ssh root@your-server 'bash -s' < staging_server_setup.sh

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
fail()    { echo -e "${RED}[ERROR]${NC} $1"; }

# Must run as root
if [[ $EUID -ne 0 ]]; then
    fail "This script must be run as root"
    exit 1
fi

DEPLOY_USER="deploy"

echo ""
echo "================================================"
echo "  Staging Server Setup"
echo "================================================"
echo ""

# ========================================
# 1. SYSTEM UPDATE & BASE PACKAGES
# ========================================
info "Updating system packages..."
apt update && apt upgrade -y
apt install -y \
    curl wget git unzip zip tar gzip jq htop \
    build-essential ca-certificates gnupg lsb-release \
    software-properties-common apt-transport-https \
    ufw fail2ban unattended-upgrades

success "Base packages installed"

# ========================================
# 2. CREATE DEPLOY USER
# ========================================
if id "$DEPLOY_USER" &>/dev/null; then
    info "User '$DEPLOY_USER' already exists, skipping"
else
    info "Creating deploy user..."
    adduser --disabled-password --gecos "" "$DEPLOY_USER"

    # Copy SSH authorized_keys from root
    mkdir -p /home/$DEPLOY_USER/.ssh
    if [ -f /root/.ssh/authorized_keys ]; then
        cp /root/.ssh/authorized_keys /home/$DEPLOY_USER/.ssh/authorized_keys
    fi
    chown -R $DEPLOY_USER:$DEPLOY_USER /home/$DEPLOY_USER/.ssh
    chmod 700 /home/$DEPLOY_USER/.ssh
    chmod 600 /home/$DEPLOY_USER/.ssh/authorized_keys 2>/dev/null || true

    # Add to sudo group (passwordless sudo)
    usermod -aG sudo "$DEPLOY_USER"
    echo "$DEPLOY_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$DEPLOY_USER

    success "Deploy user created with SSH access"
fi

# ========================================
# 3. SSH HARDENING
# ========================================
info "Hardening SSH..."
sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#\?PubkeyAuthentication .*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
systemctl restart ssh
success "SSH hardened (root login disabled, password auth disabled)"

# ========================================
# 4. FIREWALL (UFW)
# ========================================
info "Configuring UFW firewall..."
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow http
ufw allow https
echo "y" | ufw enable
success "Firewall enabled (SSH, HTTP, HTTPS)"

# ========================================
# 5. FAIL2BAN
# ========================================
info "Configuring fail2ban..."
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 7200
EOF
systemctl enable fail2ban
systemctl restart fail2ban
success "fail2ban configured"

# ========================================
# 6. UNATTENDED UPGRADES
# ========================================
info "Configuring unattended security upgrades..."
cat > /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF
systemctl enable unattended-upgrades
success "Unattended security upgrades enabled"

# ========================================
# 7. DOCKER
# ========================================
info "Installing Docker..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
usermod -aG docker "$DEPLOY_USER"
systemctl enable docker
success "Docker installed: $(docker --version)"

# ========================================
# 8. CADDY (REVERSE PROXY + AUTO TLS)
# ========================================
info "Installing Caddy..."
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
apt update
apt install -y caddy

# Create base Caddyfile with import structure for multi-project support
mkdir -p /etc/caddy/sites
cat > /etc/caddy/Caddyfile << 'EOF'
# Global options
{
    email {$CADDY_ACME_EMAIL:admin@localhost}
}

# Import all site configs
import /etc/caddy/sites/*
EOF

# Create example site config
cat > /etc/caddy/sites/example.disabled << 'EOF'
# Example: reverse proxy a staging app
# Rename to myapp.conf to enable
#
# myapp-staging.yourdomain.com {
#     reverse_proxy localhost:3000
#
#     # Optional: basic auth to restrict access
#     basicauth * {
#         staging $2a$14$HASH_HERE
#     }
# }
EOF

systemctl enable caddy
systemctl restart caddy
success "Caddy installed with multi-site config"

# ========================================
# 9. GO
# ========================================
info "Installing Go..."
GO_VERSION=$(curl -s https://go.dev/VERSION?m=text 2>/dev/null | head -n1)
GO_VERSION=${GO_VERSION#go}
if [[ -z "$GO_VERSION" ]]; then
    GO_VERSION="1.24.0"
    warn "Could not fetch latest Go version, using $GO_VERSION"
fi
cd /tmp
wget -q "https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz"
rm -rf /usr/local/go
tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
rm -f "go${GO_VERSION}.linux-amd64.tar.gz"

# Add Go to deploy user's PATH
cat >> /home/$DEPLOY_USER/.profile << 'EOF'

# Go
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
EOF
success "Go ${GO_VERSION} installed"

# ========================================
# 10. NODE.JS
# ========================================
info "Installing Node.js LTS..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt install -y nodejs
success "Node.js installed: $(node --version)"

# ========================================
# 11. GITHUB CLI
# ========================================
info "Installing GitHub CLI..."
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
apt update
apt install -y gh
success "GitHub CLI installed: $(gh --version | head -n1)"

# ========================================
# 12. STAGING DIRECTORY STRUCTURE
# ========================================
info "Creating staging directory structure..."
mkdir -p /srv/staging
chown $DEPLOY_USER:$DEPLOY_USER /srv/staging
success "Staging root: /srv/staging"

# ========================================
# 13. DEPLOY HELPER SCRIPT
# ========================================
info "Creating deploy helper..."
cat > /usr/local/bin/staging-deploy << 'SCRIPT'
#!/bin/bash
set -euo pipefail

# Usage: staging-deploy <app-name> <github-repo> [branch]
# Example: staging-deploy trader jasonKoogler/trader main

APP_NAME="${1:?Usage: staging-deploy <app-name> <github-repo> [branch]}"
REPO="${2:?Usage: staging-deploy <app-name> <github-repo> [branch]}"
BRANCH="${3:-main}"
APP_DIR="/srv/staging/$APP_NAME"

echo "Deploying $REPO ($BRANCH) to $APP_DIR..."

if [ -d "$APP_DIR" ]; then
    cd "$APP_DIR"
    git fetch origin
    git checkout "$BRANCH"
    git pull origin "$BRANCH"
else
    git clone "git@github.com:$REPO.git" "$APP_DIR"
    cd "$APP_DIR"
    git checkout "$BRANCH"
fi

# Look for docker-compose in common locations
COMPOSE_FILE=""
for f in docker-compose.yml docker-compose.yaml deploy/docker-compose.yml deploy/docker-compose.yaml; do
    if [ -f "$APP_DIR/$f" ]; then
        COMPOSE_FILE="$f"
        break
    fi
done

if [ -n "$COMPOSE_FILE" ]; then
    echo "Found $COMPOSE_FILE, running docker compose..."
    docker compose -f "$APP_DIR/$COMPOSE_FILE" pull 2>/dev/null || true
    docker compose -f "$APP_DIR/$COMPOSE_FILE" up -d --build
    echo "Done! App running via $COMPOSE_FILE"
else
    echo "No docker-compose file found. Deploy the app manually."
fi
SCRIPT
chmod +x /usr/local/bin/staging-deploy
success "Deploy helper installed: staging-deploy <app-name> <repo> [branch]"

# ========================================
# 14. LOGROTATE FOR DOCKER
# ========================================
info "Configuring Docker log rotation..."
cat > /etc/docker/daemon.json << 'EOF'
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    }
}
EOF
systemctl restart docker
success "Docker log rotation configured (10MB, 3 files)"

# ========================================
# 15. SWAP (for small VPS instances)
# ========================================
if [ ! -f /swapfile ]; then
    info "Creating 2GB swap file..."
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    # Tune swappiness for a server
    echo 'vm.swappiness=10' >> /etc/sysctl.conf
    sysctl -p
    success "2GB swap created"
else
    info "Swap already exists, skipping"
fi

# ========================================
# CLEANUP
# ========================================
info "Cleaning up..."
apt autoremove -y
apt autoclean

# ========================================
# SUMMARY
# ========================================
echo ""
echo "================================================"
echo "  Staging Server Setup Complete"
echo "================================================"
echo ""
echo "  System:"
echo "    - Ubuntu $(lsb_release -rs) with unattended security upgrades"
echo "    - UFW firewall (SSH, HTTP, HTTPS)"
echo "    - fail2ban (SSH brute-force protection)"
echo "    - 2GB swap"
echo ""
echo "  User:"
echo "    - Deploy user: $DEPLOY_USER (passwordless sudo)"
echo "    - SSH keys copied from root"
echo "    - Root login disabled"
echo ""
echo "  Software:"
echo "    - Docker $(docker --version | cut -d' ' -f3 | tr -d ',')"
echo "    - Caddy (reverse proxy + auto TLS)"
echo "    - Go ${GO_VERSION}"
echo "    - Node.js $(node --version)"
echo "    - GitHub CLI $(gh --version 2>/dev/null | head -n1 | awk '{print $NF}')"
echo ""
echo "  Structure:"
echo "    - /srv/staging/<app-name>  -- app repos"
echo "    - /etc/caddy/sites/*.conf  -- per-app Caddy configs"
echo ""
echo "  Next steps:"
echo "    1. SSH in as deploy user:  ssh $DEPLOY_USER@$(hostname -I | awk '{print $1}')"
echo "    2. Authenticate GitHub:    gh auth login --git-protocol ssh"
echo "    3. Generate SSH key:       ssh-keygen -t ed25519 && gh ssh-key add ~/.ssh/id_ed25519.pub"
echo "    4. Add a Caddy site:       sudo vi /etc/caddy/sites/myapp.conf"
echo "    5. Deploy an app:          staging-deploy myapp owner/repo main"
echo ""
echo "  Example Caddy site config (/etc/caddy/sites/trader.conf):"
echo "    trader-staging.yourdomain.com {"
echo "        reverse_proxy localhost:5173"
echo "        handle_path /api/* {"
echo "            reverse_proxy localhost:8080"
echo "        }"
echo "    }"
echo ""
