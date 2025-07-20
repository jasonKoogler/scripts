#!/bin/bash

# Complete WSL Ubuntu Development Environment Setup
# Includes all tools + Oh My Zsh + Spaceship + SSH setup + Private repo support + GitHub Auth

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

# Function to get latest Go version
get_latest_go_version() {
    print_status "Fetching latest Go version..."
    local latest_version
    latest_version=$(curl -s https://go.dev/VERSION?m=text | head -n1)
    if [[ -z "$latest_version" ]]; then
        print_warning "Could not fetch latest Go version, using fallback 1.21.6"
        echo "1.21.6"
    else
        echo "${latest_version#go}"  # Remove 'go' prefix
    fi
}

# Function to verify tool installation
verify_tool() {
    local tool=$1
    local version_flag=${2:-"--version"}
    
    if command -v "$tool" >/dev/null 2>&1; then
        print_success "$tool installed: $($tool $version_flag 2>/dev/null | head -n1)"
        return 0
    else
        print_error "$tool installation failed"
        return 1
    fi
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
verify_tool git

# Install Zsh
print_status "Installing Zsh..."
sudo apt install -y zsh
verify_tool zsh

# Install Node.js and npm (using NodeSource repository)
print_status "Installing Node.js and npm..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs
verify_tool node
verify_tool npm

# Install Go (dynamic version)
print_status "Installing Go..."
GO_VERSION=$(get_latest_go_version)
cd /tmp
wget "https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
print_success "Go ${GO_VERSION} installed"

# Install GitHub CLI
print_status "Installing GitHub CLI..."
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install -y gh
verify_tool gh

# Install Python3 and pip
print_status "Installing Python3 and pip..."
sudo apt install -y python3 python3-pip python3-venv python3-dev
verify_tool python3

# ========================================
# TERMINAL & FILE NAVIGATION TOOLS
# ========================================
print_section "Terminal & File Navigation Tools"

# Install tmux
print_status "Installing tmux..."
sudo apt install -y tmux
verify_tool tmux -V

# Install tree
print_status "Installing tree..."
sudo apt install -y tree
verify_tool tree

# Install fzf
print_status "Installing fzf..."
sudo apt install -y fzf
print_success "fzf installed"

# Install ripgrep
print_status "Installing ripgrep..."
sudo apt install -y ripgrep
verify_tool rg

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
verify_tool eza

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
verify_tool htop

# Install btop
print_status "Installing btop..."
sudo apt install -y btop
verify_tool btop

# Install ncdu
print_status "Installing ncdu..."
sudo apt install -y ncdu
verify_tool ncdu

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
verify_tool docker

# Install jq
print_status "Installing jq..."
sudo apt install -y jq
verify_tool jq

# Install httpie
print_status "Installing httpie..."
sudo apt install -y httpie
verify_tool http

# Install additional useful tools
print_status "Installing additional development tools..."
sudo apt install -y vim neovim unzip zip tar gzip
verify_tool vim
verify_tool nvim

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
  git_last_commit    # Last commit message (custom section)
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
    export GOPATH=$HOME/go
    export PATH=$PATH:$GOPATH/bin
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
alias glog='git log --oneline --graph --decorate'

# Docker aliases
alias dps='docker ps'
alias di='docker images'
alias dc='docker-compose'
alias dcu='docker-compose up'
alias dcd='docker-compose down'
alias dclean='docker system prune -f'

# System aliases
alias h='history'
alias c='clear'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias reload='source ~/.zshrc'

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

# Development aliases
alias serve='python3 -m http.server 8000'
alias mypy='python3'
alias editrc='nvim ~/.zshrc'
alias showpath='echo $PATH | tr ":" "\n"'
EOF

# ========================================
# CUSTOM SPACESHIP CONFIGURATION
# ========================================
print_status "Setting up custom Spaceship configuration with commit messages..."
mkdir -p ~/.config/spaceship
cat > ~/.config/spaceship/spaceship.zsh << 'EOF'
# Custom Spaceship configuration with last commit message

# Add custom git commit section
spaceship_git_last_commit() {
  [[ $SPACESHIP_GIT_LAST_COMMIT_SHOW == false ]] && return
  
  # Check if we're in a git repo
  spaceship::is_git || return
  
  # Get the last commit message (truncated to 50 chars)
  local commit_msg=$(git log -1 --pretty=format:"%s" 2>/dev/null | cut -c1-50)
  [[ -z $commit_msg ]] && return
  
  # Add ellipsis if truncated
  [[ ${#$(git log -1 --pretty=format:"%s" 2>/dev/null)} -gt 50 ]] && commit_msg="${commit_msg}..."
  
  spaceship::section \
    --color "$SPACESHIP_GIT_LAST_COMMIT_COLOR" \
    "$SPACESHIP_GIT_LAST_COMMIT_PREFIX$commit_msg$SPACESHIP_GIT_LAST_COMMIT_SUFFIX" 
}

# Configure the commit section
SPACESHIP_GIT_LAST_COMMIT_SHOW=true
SPACESHIP_GIT_LAST_COMMIT_PREFIX=""
SPACESHIP_GIT_LAST_COMMIT_SUFFIX=" "
SPACESHIP_GIT_LAST_COMMIT_COLOR="yellow"
EOF

# Add spaceship config to zshrc
echo 'source ~/.config/spaceship/spaceship.zsh' >> ~/.zshrc

# ========================================
# SSH & GITHUB CONFIGURATION
# ========================================
print_section "SSH & GitHub Configuration"
print_status "Setting up SSH directory and configuration..."

# Create .ssh directory if it doesn't exist
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Create SSH config template
if [ ! -f ~/.ssh/config ]; then
    touch ~/.ssh/config
    chmod 600 ~/.ssh/config
fi

# GitHub SSH Setup
print_status "Setting up GitHub SSH authentication..."
read -p "🔑 Enter your GitHub email: " GITHUB_EMAIL
read -p "🔑 Enter your GitHub username: " GITHUB_USERNAME
read -p "🔑 Enter your full name for Git config: " FULL_NAME

# Generate SSH key
print_status "Generating SSH key..."
ssh-keygen -t ed25519 -C "$GITHUB_EMAIL" -f ~/.ssh/github_key -N ""

# Add SSH key to agent
print_status "Adding SSH key to SSH agent..."
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/github_key

# Create/update SSH config
print_status "Creating SSH config..."
cat > ~/.ssh/config << EOF
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/github_key
    IdentitiesOnly yes
EOF

chmod 600 ~/.ssh/config

# Configure Git
print_status "Configuring Git..."
git config --global user.name "$FULL_NAME"
git config --global user.email "$GITHUB_EMAIL"
git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global core.editor "nvim"

# Set up GitHub CLI
print_status "Setting up GitHub CLI..."
print_warning "You'll need to authenticate with GitHub CLI next."
gh auth login --git-protocol ssh

# Test SSH connection
print_status "Testing SSH connection to GitHub..."
sleep 2
if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    print_success "SSH connection to GitHub successful!"
else
    print_warning "SSH connection test inconclusive. Make sure you've added the public key to GitHub."
fi

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
# FINAL CONFIGURATION
# ========================================
print_section "Final Configuration"

# Create useful directories
mkdir -p ~/projects ~/scripts ~/bin

# Add some useful scripts
cat > ~/scripts/update-system.sh << 'EOF'
#!/bin/bash
echo "🔄 Updating system..."
sudo apt update && sudo apt upgrade -y
echo "🔄 Updating npm packages..."
npm update -g
echo "🔄 Updating Oh My Zsh..."
cd ~/.oh-my-zsh && git pull
echo "✅ System update complete!"
EOF

chmod +x ~/scripts/update-system.sh

# ========================================
# CLEANUP
# ========================================
print_section "Cleanup"
print_status "Cleaning up temporary files..."
rm -f /tmp/go*.tar.gz
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
echo "  ✅ Go: ${GO_VERSION}"
echo "  ✅ GitHub CLI: $(gh --version | head -n1 | cut -d' ' -f3)"
echo "  ✅ Python3: $(python3 --version)"
echo "  ✅ Rust: Available via rustup"
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
echo "  ✅ vim & neovim"
echo ""
echo "🔄 Version Managers:"
echo "  ✅ nvm, pyenv, rustup"
echo ""
echo "🔑 SSH & GitHub Setup:"
echo "  ✅ SSH key generated and configured"
echo "  ✅ GitHub CLI authenticated"
echo "  ✅ Git configured with your details"
echo ""
echo "✨ Shell Enhancements:"
echo "  ✅ Oh My Zsh with comprehensive plugins"
echo "  ✅ Spaceship theme with commit messages"
echo "  ✅ Smart aliases and navigation"
echo ""
echo "🔧 Your SSH Public Key (already configured):"
echo "=========================================="
cat ~/.ssh/github_key.pub
echo "=========================================="
echo ""
echo "🎯 Ready to Use Features:"
echo "  • All repositories cloned with 'gh repo clone' will use SSH automatically"
echo "  • Smart directory jumping: z directory_name"
echo "  • Beautiful file listing: ll, ls"
echo "  • Better search: grep (powered by ripgrep)"
echo "  • Syntax highlighted viewing: cat (powered by bat)"
echo "  • Archive extraction: extract filename.zip"
echo "  • System updates: ~/scripts/update-system.sh"
echo ""
echo "🚀 Next Steps:"
echo "  1. Restart your terminal: exec zsh"
echo "  2. Change default shell: chsh -s \$(which zsh)"
echo "  3. Test git operations: gh repo clone username/repo"
echo "  4. Start coding! 🎉"
echo ""
print_success "Your development environment is fully configured and ready! 🚀"
print_warning "Don't forget to restart your terminal or run 'exec zsh' to use the new shell!"
