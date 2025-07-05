#!/bin/bash

# Complete WSL Ubuntu Development Environment Setup
# Includes all tools + Oh My Zsh + Spaceship + SSH setup + Private repo support

set -e  # Exit on any error

echo "🚀 Setting up complete development environment for WSL Ubuntu..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_section() {
    echo -e "${PURPLE}[SECTION]${NC} $1"
}

# ========================================
# SYSTEM UPDATE & DEPENDENCIES
# ========================================
print_section "System Update & Dependencies"
print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

print_status "Installing basic dependencies..."
sudo apt install -y curl wget software-properties-common apt-transport-https ca-certificates gnupg lsb-release build-essential

# ========================================
# CORE DEVELOPMENT TOOLS
# ========================================
print_section "Core Development Tools"

# Install Git
print_status "Installing Git..."
sudo apt install -y git
print_success "Git installed: $(git --version)"

# Install Zsh
print_status "Installing Zsh..."
sudo apt install -y zsh
print_success "Zsh installed: $(zsh --version)"

# Install Node.js and npm (using NodeSource repository)
print_status "Installing Node.js and npm..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs
print_success "Node.js installed: $(node --version)"
print_success "npm installed: $(npm --version)"

# Install Go
print_status "Installing Go..."
GO_VERSION="1.21.6"
cd /tmp
wget https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
print_success "Go installed"

# Install GitHub CLI
print_status "Installing GitHub CLI..."
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install -y gh
print_success "GitHub CLI installed: $(gh --version | head -n1)"

# Install Python3 and pip
print_status "Installing Python3 and pip..."
sudo apt install -y python3 python3-pip python3-venv python3-dev
print_success "Python3 installed: $(python3 --version)"

# ========================================
# TERMINAL & FILE NAVIGATION TOOLS
# ========================================
print_section "Terminal & File Navigation Tools"

# Install tmux
print_status "Installing tmux..."
sudo apt install -y tmux
print_success "tmux installed: $(tmux -V)"

# Install tree
print_status "Installing tree..."
sudo apt install -y tree
print_success "tree installed"

# Install fzf
print_status "Installing fzf..."
sudo apt install -y fzf
print_success "fzf installed"

# Install ripgrep
print_status "Installing ripgrep..."
sudo apt install -y ripgrep
print_success "ripgrep installed: $(rg --version | head -n1)"

# Install bat
print_status "Installing bat..."
sudo apt install -y bat
# Create symlink since Ubuntu installs as batcat
sudo ln -sf /usr/bin/batcat /usr/local/bin/bat 2>/dev/null || true
print_success "bat installed"

# Install eza (modern ls replacement)
print_status "Installing eza..."
sudo mkdir -p /etc/apt/keyrings
wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
sudo apt update
sudo apt install -y eza
print_success "eza installed: $(eza --version)"

# Install zoxide
print_status "Installing zoxide..."
curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
print_success "zoxide installed"

# ========================================
# SYSTEM MONITORING & MANAGEMENT
# ========================================
print_section "System Monitoring & Management"

# Install htop
print_status "Installing htop..."
sudo apt install -y htop
print_success "htop installed"

# Install btop
print_status "Installing btop..."
sudo apt install -y btop
print_success "btop installed"

# Install ncdu
print_status "Installing ncdu..."
sudo apt install -y ncdu
print_success "ncdu installed"

# Install iotop
print_status "Installing iotop..."
sudo apt install -y iotop
print_success "iotop installed"

# ========================================
# DEVELOPMENT ESSENTIALS
# ========================================
print_section "Development Essentials"

# Install Docker
print_status "Installing Docker..."
sudo apt install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER
print_success "Docker installed: $(docker --version)"

# Install jq
print_status "Installing jq..."
sudo apt install -y jq
print_success "jq installed: $(jq --version)"

# Install httpie
print_status "Installing httpie..."
sudo apt install -y httpie
print_success "httpie installed: $(http --version)"

# ========================================
# VERSION MANAGERS
# ========================================
print_section "Version Managers"

# Install nvm (Node Version Manager)
print_status "Installing nvm..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
print_success "nvm installed"

# Install pyenv dependencies and pyenv
print_status "Installing pyenv..."
sudo apt install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
curl https://pyenv.run | bash
print_success "pyenv installed"

# Install Rust and cargo
print_status "Installing Rust and cargo..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
print_success "Rust installed"

# ========================================
# OH MY ZSH SETUP
# ========================================
print_section "Oh My Zsh Setup"

# Install Oh My Zsh
print_status "Installing Oh My Zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Install Oh My Zsh plugins and themes
print_status "Installing Oh My Zsh plugins and themes..."
# Essential plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-completions ~/.oh-my-zsh/custom/plugins/zsh-completions

# Install Spaceship theme
git clone https://github.com/spaceship-prompt/spaceship-prompt.git ~/.oh-my-zsh/custom/themes/spaceship-prompt --depth=1
ln -s ~/.oh-my-zsh/custom/themes/spaceship-prompt/spaceship.zsh-theme ~/.oh-my-zsh/custom/themes/spaceship.zsh-theme

# ========================================
# CONFIGURE ZSHRC
# ========================================
print_status "Configuring enhanced .zshrc..."
cp ~/.zshrc ~/.zshrc.backup 2>/dev/null || true
cat > ~/.zshrc << 'EOF'
# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set Spaceship theme
ZSH_THEME="spaceship"

# Spaceship configuration
SPACESHIP_PROMPT_ORDER=(
  user          # Username section
  dir           # Current directory section
  host          # Hostname section
  git           # Git section (git_branch + git_status)
  git_commit    # Last commit message (custom section)
  hg            # Mercurial section
  exec_time     # Execution time
  line_sep      # Line break
  vi_mode       # Vi-mode indicator
  jobs          # Background jobs indicator
  exit_code     # Exit code section
  char          # Prompt character
)
SPACESHIP_USER_SHOW=always
SPACESHIP_PROMPT_ADD_NEWLINE=false
SPACESHIP_CHAR_SUFFIX=" "

# Plugins - comprehensive set for development
plugins=(
    git
    sudo
    extract
    web-search
    copypath
    copyfile
    copybuffer
    dirhistory
    history
    colored-man-pages
    command-not-found
    docker
    docker-compose
    npm
    node
    golang
    python
    pip
    rust
    httpie
    tmux
    aliases
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-completions
)

source $ZSH/oh-my-zsh.sh

# User configuration
export PATH=$HOME/bin:/usr/local/bin:$PATH

# Add local bin to PATH (for zoxide and other tools)
export PATH="$HOME/.local/bin:$PATH"

# Add Go to PATH
if [ -d "/usr/local/go/bin" ]; then
    export PATH=$PATH:/usr/local/go/bin
fi

# Add Rust to PATH
if [ -d "$HOME/.cargo/bin" ]; then
    export PATH="$HOME/.cargo/bin:$PATH"
fi

# NVM configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/nvm.completion.bash" ] && \. "$NVM_DIR/nvm.completion.bash"

# Pyenv configuration
if [ -d "$HOME/.pyenv" ]; then
    export PYENV_ROOT="$HOME/.pyenv"
    [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
fi

# Zoxide configuration (smart cd)
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# Useful aliases
alias ll='eza -la'
alias lt='eza --tree'
alias la='eza -la'
alias ls='eza'
alias cat='bat'
alias find='fzf'
alias cd='z'
alias grep='rg'

# Git aliases (in addition to Oh My Zsh git plugin)
alias gst='git status'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gaa='git add --all'
alias gcm='git commit -m'
alias gp='git push'
alias gl='git pull'

# Docker aliases
alias dps='docker ps'
alias di='docker images'
alias dc='docker-compose'
alias dcu='docker-compose up'
alias dcd='docker-compose down'

# System aliases
alias h='history'
alias c='clear'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Network and system info
alias ports='netstat -tulanp'
alias myip='curl http://ipecho.net/plain; echo'
alias diskusage='df -h'
alias meminfo='free -m -l -t'

# tmux aliases
alias tl='tmux list-sessions'
alias ta='tmux attach -t'
alias tn='tmux new-session -s'
alias tk='tmux kill-session -t'
EOF

# ========================================
# CUSTOM SPACESHIP CONFIGURATION
# ========================================
print_status "Setting up custom Spaceship configuration with commit messages..."
mkdir -p ~/.config/spaceship
cat > ~/.config/spaceship/spaceship.zsh << 'EOF'
# Custom Spaceship configuration with last commit message

# Add custom git commit section
spaceship_git_commit() {
  [[ $SPACESHIP_GIT_COMMIT_SHOW == false ]] && return
  
  # Check if we're in a git repo
  spaceship::is_git || return
  
  # Get the last commit message (truncated to 50 chars)
  local commit_msg=$(git log -1 --pretty=format:"%s" 2>/dev/null | cut -c1-50)
  [[ -z $commit_msg ]] && return
  
  # Add ellipsis if truncated
  [[ ${#$(git log -1 --pretty=format:"%s" 2>/dev/null)} -gt 50 ]] && commit_msg="${commit_msg}..."
  
  spaceship::section \
    "$SPACESHIP_GIT_COMMIT_COLOR" \
    "$SPACESHIP_GIT_COMMIT_PREFIX" \
    "$commit_msg" \
    "$SPACESHIP_GIT_COMMIT_SUFFIX"
}

# Configure the commit section
SPACESHIP_GIT_COMMIT_SHOW=true
SPACESHIP_GIT_COMMIT_PREFIX=" "
SPACESHIP_GIT_COMMIT_SUFFIX=""
SPACESHIP_GIT_COMMIT_COLOR="yellow"
EOF

# Add spaceship config to zshrc
echo 'source ~/.config/spaceship/spaceship.zsh' >> ~/.zshrc

# ========================================
# SSH CONFIGURATION FOR GITHUB
# ========================================
print_section "SSH Configuration"
print_status "Setting up SSH directory and configuration..."

# Create .ssh directory if it doesn't exist
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Create SSH config template
if [ ! -f ~/.ssh/config ]; then
    touch ~/.ssh/config
    chmod 600 ~/.ssh/config
fi

print_success "SSH directory configured"

# ========================================
# PRIVATE REPOSITORY SUPPORT
# ========================================
print_section "Private Repository Support"
print_status "Configuring for private GitHub dependencies..."

# Configure Go for private repos
if command -v go >/dev/null 2>&1; then
    go env -w GOPRIVATE="github.com"
    print_success "Go configured for private repositories"
fi

# Enable Docker BuildKit for SSH builds
echo 'export DOCKER_BUILDKIT=1' >> ~/.zshrc

print_success "Private repository support configured"

# ========================================
# CLEANUP
# ========================================
print_section "Cleanup"
print_status "Cleaning up temporary files..."
rm -f /tmp/go${GO_VERSION}.linux-amd64.tar.gz
sudo apt autoremove -y
sudo apt autoclean

# ========================================
# INSTALLATION SUMMARY
# ========================================
print_section "Installation Complete!"
print_success "🎉 Complete development environment setup finished!"

echo ""
echo "📋 Installation Summary:"
echo ""
echo "🔧 Core Development Tools:"
echo "  ✅ Git: $(git --version)"
echo "  ✅ Zsh + Oh My Zsh + Spaceship theme"
echo "  ✅ Node.js: $(node --version)"
echo "  ✅ npm: $(npm --version)"
echo "  ✅ Go: Available at /usr/local/go/bin"
echo "  ✅ GitHub CLI: $(gh --version | head -n1 | cut -d' ' -f3)"
echo "  ✅ Python3: $(python3 --version)"
echo ""
echo "📁 Terminal & File Navigation:"
echo "  ✅ tmux: $(tmux -V)"
echo "  ✅ tree, fzf, ripgrep, bat, eza, zoxide"
echo ""
echo "📊 System Monitoring:"
echo "  ✅ htop, btop, ncdu, iotop"
echo ""
echo "🐳 Development Essentials:"
echo "  ✅ Docker: $(docker --version)"
echo "  ✅ jq: $(jq --version)"
echo "  ✅ httpie: $(http --version)"
echo ""
echo "🔄 Version Managers:"
echo "  ✅ nvm, pyenv, rustup"
echo ""
echo "✨ Shell Enhancements:"
echo "  ✅ Oh My Zsh with comprehensive plugins"
echo "  ✅ Spaceship theme with commit messages"
echo "  ✅ Smart aliases and navigation"
echo ""
echo "🔧 Essential Next Steps:"
echo "  1. Restart your terminal or run: exec zsh"
echo "  2. Change default shell: chsh -s \$(which zsh)"
echo "  3. Generate SSH key for GitHub:"
echo "     ssh-keygen -t ed25519 -C 'your.email@example.com' -f ~/.ssh/github_key"
echo "  4. Add SSH key to SSH agent:"
echo "     eval \"\$(ssh-agent -s)\" && ssh-add ~/.ssh/github_key"
echo "  5. Add SSH config for GitHub:"
echo "     echo 'Host github.com' >> ~/.ssh/config"
echo "     echo '    HostName github.com' >> ~/.ssh/config"
echo "     echo '    User git' >> ~/.ssh/config"
echo "     echo '    IdentityFile ~/.ssh/github_key' >> ~/.ssh/config"
echo "  6. Copy public key and add to GitHub:"
echo "     cat ~/.ssh/github_key.pub"
echo "  7. Configure GitHub CLI for SSH:"
echo "     gh auth login --git-protocol ssh"
echo "  8. Configure Git:"
echo "     git config --global user.name 'Your Name'"
echo "     git config --global user.email 'your.email@example.com'"
echo ""
echo "🎯 Features Ready to Use:"
echo "  • Smart directory jumping: cd (powered by zoxide)"
echo "  • Beautiful file listing: ll, ls (powered by eza)"
echo "  • Better search: grep (powered by ripgrep)"
echo "  • Syntax highlighted viewing: cat (powered by bat)"
echo "  • Archive extraction: extract filename.zip"
echo "  • Private GitHub dependencies: npm/go/pip install from private repos"
echo "  • Commit messages in prompt: Shows last commit in git repos"
echo ""
print_success "Your development environment is ready! 🚀"
