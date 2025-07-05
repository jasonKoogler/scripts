#!/bin/bash

# Go 1.24.0 Update Script for Ubuntu WSL2
# This script downloads and installs Go 1.24.0, replacing any existing installation

set -e  # Exit on any error

GO_VERSION="1.24.0"
GO_OS="linux"
GO_ARCH="amd64"
GO_TARBALL="go${GO_VERSION}.${GO_OS}-${GO_ARCH}.tar.gz"
GO_URL="https://golang.org/dl/${GO_TARBALL}"
INSTALL_DIR="/usr/local"
GO_PATH="${INSTALL_DIR}/go"

echo "🚀 Go ${GO_VERSION} Update Script for Ubuntu WSL2"
echo "=================================================="

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "❌ This script should not be run as root. Please run without sudo."
   echo "   The script will prompt for sudo when needed."
   exit 1
fi

# Check current Go version if installed
echo "📋 Checking current Go installation..."
if command -v go &> /dev/null; then
    CURRENT_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
    echo "   Current version: ${CURRENT_VERSION}"
    if [[ "${CURRENT_VERSION}" == "${GO_VERSION}" ]]; then
        echo "✅ Go ${GO_VERSION} is already installed!"
        exit 0
    fi
else
    echo "   No Go installation found"
fi

# Create temporary directory
TEMP_DIR=$(mktemp -d)
echo "📁 Using temporary directory: ${TEMP_DIR}"

# Download Go tarball
echo "⬇️  Downloading Go ${GO_VERSION}..."
cd "${TEMP_DIR}"
if wget -q --show-progress "${GO_URL}"; then
    echo "✅ Downloaded successfully"
else
    echo "❌ Failed to download Go ${GO_VERSION}"
    rm -rf "${TEMP_DIR}"
    exit 1
fi

# Verify download
echo "🔍 Verifying download..."
if [[ ! -f "${GO_TARBALL}" ]]; then
    echo "❌ Downloaded file not found"
    rm -rf "${TEMP_DIR}"
    exit 1
fi

# Remove existing Go installation
echo "🗑️  Removing existing Go installation..."
if [[ -d "${GO_PATH}" ]]; then
    sudo rm -rf "${GO_PATH}"
    echo "   Removed existing installation from ${GO_PATH}"
else
    echo "   No existing installation found in ${GO_PATH}"
fi

# Extract and install new Go version
echo "📦 Installing Go ${GO_VERSION}..."
sudo tar -C "${INSTALL_DIR}" -xzf "${GO_TARBALL}"
echo "✅ Go ${GO_VERSION} installed to ${GO_PATH}"

# Update PATH in shell profiles
echo "🔧 Updating shell configuration..."

# Function to update shell profile
update_shell_profile() {
    local profile_file="$1"
    local profile_name="$2"
    
    if [[ -f "${profile_file}" ]]; then
        # Remove existing Go PATH entries
        sed -i '/# Go programming language/d' "${profile_file}"
        sed -i '/export PATH.*\/go\/bin/d' "${profile_file}"
        sed -i '/export GOPATH/d' "${profile_file}"
        sed -i '/export GOROOT/d' "${profile_file}"
        
        # Add new Go configuration
        cat >> "${profile_file}" << 'EOF'

# Go programming language
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
EOF
        echo "   Updated ${profile_name}"
    fi
}

# Update common shell profiles
update_shell_profile "$HOME/.bashrc" ".bashrc"
update_shell_profile "$HOME/.zshrc" ".zshrc" 
update_shell_profile "$HOME/.profile" ".profile"

# Clean up
echo "🧹 Cleaning up..."
rm -rf "${TEMP_DIR}"

# Verify installation
echo "✅ Verifying installation..."
export PATH="/usr/local/go/bin:$PATH"
sleep 3
if /usr/local/go/bin/go version &> /dev/null; then
    NEW_VERSION=$(/usr/local/go/bin/go version | awk '{print $3}' | sed 's/go//')
    echo "🎉 Successfully installed Go ${NEW_VERSION}"
else
    echo "❌ Installation verification failed"
    exit 1
fi

echo ""
echo "🎯 Installation Complete!"
echo "========================"
echo "📌 Go ${GO_VERSION} has been installed to: ${GO_PATH}"
echo "📌 GOROOT: /usr/local/go"
echo "📌 GOPATH: \$HOME/go (~/go)"
echo ""
echo "🔄 To use Go immediately, run:"
echo "   source ~/.bashrc"
echo "   # or restart your terminal"
echo ""
echo "🧪 Test your installation:"
echo "   go version"
echo "   go env"
echo ""
echo "✨ Happy coding with Go ${GO_VERSION}!"
