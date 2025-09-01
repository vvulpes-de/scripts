#!/bin/bash
# ============================================================
# SSH Key Generator Script
# This script generates a new SSH key pair (Ed25519).
# Author: <your name>
# ============================================================

# 1. Set default values
EMAIL="your.email@example.com"         # Email comment for the key
KEY_TYPE="ed25519"                     # Key type (ed25519 recommended)
KEY_DIR="$HOME/.ssh"                   # Directory to store keys
KEY_FILE="$KEY_DIR/id_${KEY_TYPE}"     # Private key file path

# 2. Create .ssh directory if it does not exist
if [ ! -d "$KEY_DIR" ]; then
    echo "[INFO] Creating $KEY_DIR directory..."
    mkdir -p "$KEY_DIR"
    chmod 700 "$KEY_DIR"
fi

# 3. Generate SSH key
# -t : key type
# -C : key comment (usually email)
# -f : output file
# -N : passphrase (empty = no passphrase)
echo "[INFO] Generating new SSH key..."
ssh-keygen -t "$KEY_TYPE" -C "$EMAIL" -f "$KEY_FILE" -N ""

# 4. Adjust permissions
chmod 600 "$KEY_FILE"
chmod 644 "$KEY_FILE.pub"

# 5. Print success message
echo "[SUCCESS] SSH key generated!"
echo "Private key: $KEY_FILE"
echo "Public key : ${KEY_FILE}.pub"

# 6. Display the public key for easy copy-paste
echo
echo "=== Your Public Key (copy this to GitHub/GitLab/Server) ==="
cat "${KEY_FILE}.pub"
echo "=========================================================="
