#!/bin/bash
# ============================================================
# SSH Key Generator Script
# This script generates a new SSH key pair with safety checks.
# Usage: ./generate_ssh_key.sh [OPTIONS]
# Options:
#   -e EMAIL     Email for the key comment (required)
#   -n NAME      Custom name for the key file (optional)
#   -t TYPE      Key type: ed25519, rsa, ecdsa (default: ed25519)
#   -h           Show this help message
# ============================================================

# Default values
DEFAULT_EMAIL=""
DEFAULT_KEY_TYPE="ed25519"
DEFAULT_KEY_DIR="$HOME/.ssh"

# Function to show usage
show_usage() {
    echo "Usage: $0 -e EMAIL [-n NAME] [-t TYPE] [-h]"
    echo ""
    echo "Options:"
    echo "  -e EMAIL     Email address for the key comment (required)"
    echo "  -n NAME      Custom name for the key file (default: id_TYPE)"
    echo "  -t TYPE      Key type: ed25519, rsa, ecdsa (default: ed25519)"
    echo "  -h           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -e user@example.com"
    echo "  $0 -e user@example.com -n my_custom_key"
    echo "  $0 -e user@example.com -n github_key -t rsa"
}

# Function to validate key type
validate_key_type() {
    case "$1" in
        ed25519|rsa|ecdsa)
            return 0
            ;;
        *)
            echo "[ERROR] Invalid key type: $1"
            echo "[ERROR] Supported types: ed25519, rsa, ecdsa"
            return 1
            ;;
    esac
}

# Function to check if ssh-keygen is installed
check_ssh_keygen() {
    if ! command -v ssh-keygen &> /dev/null; then
        echo "[ERROR] ssh-keygen is not installed on your system!"
        echo ""
        echo "ssh-keygen is required to generate SSH keys."
        echo "It's usually pre-installed on most Linux/macOS systems."
        echo ""
        
        # Detect the operating system and suggest installation
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            if command -v apt &> /dev/null; then
                echo "To install on Ubuntu/Debian, run:"
                echo "sudo apt update && sudo apt install openssh-client"
            elif command -v yum &> /dev/null; then
                echo "To install on CentOS/RHEL, run:"
                echo "sudo yum install openssh-clients"
            elif command -v dnf &> /dev/null; then
                echo "To install on Fedora, run:"
                echo "sudo dnf install openssh-clients"
            elif command -v pacman &> /dev/null; then
                echo "To install on Arch Linux, run:"
                echo "sudo pacman -S openssh"
            else
                echo "Please install openssh-client package using your distribution's package manager."
            fi
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            echo "On macOS, ssh-keygen should be pre-installed."
            echo "If missing, install Xcode Command Line Tools:"
            echo "xcode-select --install"
        else
            echo "Please install OpenSSH client for your operating system."
        fi
        
        echo ""
        read -p "Would you like me to try installing it automatically? (y/N): " -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_ssh_keygen
        else
            echo "[ERROR] Cannot proceed without ssh-keygen. Please install it and try again."
            exit 1
        fi
    fi
}

# Function to automatically install ssh-keygen
install_ssh_keygen() {
    echo "[INFO] Attempting to install ssh-keygen..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt &> /dev/null; then
            sudo apt update && sudo apt install -y openssh-client
        elif command -v yum &> /dev/null; then
            sudo yum install -y openssh-clients
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y openssh-clients
        elif command -v pacman &> /dev/null; then
            sudo pacman -S --noconfirm openssh
        else
            echo "[ERROR] Could not detect package manager. Please install manually."
            exit 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "[INFO] On macOS, trying to install Xcode Command Line Tools..."
        xcode-select --install
    else
        echo "[ERROR] Automatic installation not supported for your OS."
        exit 1
    fi
    
    # Verify installation
    if command -v ssh-keygen &> /dev/null; then
        echo "[SUCCESS] ssh-keygen installed successfully!"
    else
        echo "[ERROR] Failed to install ssh-keygen. Please install manually."
        exit 1
    fi
}

# Function to generate unique filename if file exists
get_unique_filename() {
    local base_file="$1"
    local counter=1
    local unique_file="$base_file"
    
    while [ -f "$unique_file" ] || [ -f "${unique_file}.pub" ]; do
        unique_file="${base_file}_${counter}"
        counter=$((counter + 1))
    done
    
    echo "$unique_file"
}

# Parse command line arguments
EMAIL=""
KEY_NAME=""
KEY_TYPE="$DEFAULT_KEY_TYPE"

while getopts "e:n:t:h" opt; do
    case $opt in
        e)
            EMAIL="$OPTARG"
            ;;
        n)
            KEY_NAME="$OPTARG"
            ;;
        t)
            KEY_TYPE="$OPTARG"
            ;;
        h)
            show_usage
            exit 0
            ;;
        \?)
            echo "[ERROR] Invalid option: -$OPTARG" >&2
            show_usage
            exit 1
            ;;
    esac
done

# Check if email is provided
if [ -z "$EMAIL" ]; then
    echo "[ERROR] Email address is required!"
    echo ""
    show_usage
    exit 1
fi

# Check if ssh-keygen is installed
check_ssh_keygen

# Validate key type
if ! validate_key_type "$KEY_TYPE"; then
    exit 1
fi

# Set key directory and file paths
KEY_DIR="$DEFAULT_KEY_DIR"
if [ -z "$KEY_NAME" ]; then
    KEY_FILE="$KEY_DIR/id_${KEY_TYPE}"
else
    KEY_FILE="$KEY_DIR/${KEY_NAME}"
fi

# Create .ssh directory if it doesn't exist
if [ ! -d "$KEY_DIR" ]; then
    echo "[INFO] Creating $KEY_DIR directory..."
    mkdir -p "$KEY_DIR"
    chmod 700 "$KEY_DIR"
fi

# Check if key already exists and get unique name if needed
if [ -f "$KEY_FILE" ] || [ -f "${KEY_FILE}.pub" ]; then
    echo "[WARNING] SSH key already exists at $KEY_FILE"
    UNIQUE_KEY_FILE=$(get_unique_filename "$KEY_FILE")
    echo "[INFO] Using unique filename: $UNIQUE_KEY_FILE"
    KEY_FILE="$UNIQUE_KEY_FILE"
fi

# Generate SSH key
echo "[INFO] Generating new $KEY_TYPE SSH key..."
echo "[INFO] Email: $EMAIL"
echo "[INFO] Key file: $KEY_FILE"

ssh-keygen -t "$KEY_TYPE" -C "$EMAIL" -f "$KEY_FILE" -N ""

# Check if key generation was successful
if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to generate SSH key!"
    exit 1
fi

# Set proper permissions
chmod 600 "$KEY_FILE"
chmod 644 "${KEY_FILE}.pub"

# Print success message
echo ""
echo "[SUCCESS] SSH key generated successfully!"
echo "Private key: $KEY_FILE"
echo "Public key: ${KEY_FILE}.pub"

# Display the public key for easy copy-paste
echo ""
echo "=== Your Public Key (copy this to GitHub/GitLab/Server) ==="
cat "${KEY_FILE}.pub"
echo "============================================================"

# Show additional instructions
echo ""
echo "[INFO] To add this key to your SSH agent, run:"
echo "ssh-add $KEY_FILE"
echo ""
echo "[INFO] To test the connection (for GitHub), run:"
echo "ssh -T git@github.com"
