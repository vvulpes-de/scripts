#!/bin/bash

# Script to create a new user with sudo privileges
# Usage: ./create_user_with_sudo.sh <username> [ssh_public_key]

set -e  # Exit on any error

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root" >&2
   exit 1
fi

# Check if username is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <username> [ssh_public_key]"
    echo "Example: $0 devuser"
    echo "Example with SSH key: $0 devuser 'ssh-rsa AAAAB3NzaC1yc2EAAAA...'"
    exit 1
fi

USERNAME=$1
SSH_KEY=$2

# Check if user already exists
if id "$USERNAME" &>/dev/null; then
    echo "Error: User '$USERNAME' already exists"
    exit 1
fi

echo "Creating user '$USERNAME'..."

# Create the user
adduser "$USERNAME"

# Add user to sudo/wheel group (depending on distribution)
if getent group sudo >/dev/null 2>&1; then
    echo "Adding user '$USERNAME' to sudo group..."
    usermod -aG sudo "$USERNAME"
elif getent group wheel >/dev/null 2>&1; then
    echo "Adding user '$USERNAME' to wheel group..."
    usermod -aG wheel "$USERNAME"
else
    echo "Warning: Neither 'sudo' nor 'wheel' group found. Please add user to appropriate admin group manually."
fi

# Create .ssh directory for the user
echo "Setting up SSH directory for user '$USERNAME'..."
sudo -u "$USERNAME" mkdir -p "/home/$USERNAME/.ssh"
sudo -u "$USERNAME" chmod 700 "/home/$USERNAME/.ssh"
sudo -u "$USERNAME" touch "/home/$USERNAME/.ssh/authorized_keys"
sudo -u "$USERNAME" chmod 600 "/home/$USERNAME/.ssh/authorized_keys"

# Add SSH key if provided
if [ -n "$SSH_KEY" ]; then
    echo "Adding provided SSH key to authorized_keys..."
    echo "$SSH_KEY" | sudo -u "$USERNAME" tee "/home/$USERNAME/.ssh/authorized_keys" > /dev/null
    echo "SSH key has been added successfully!"
fi

echo ""
echo "User '$USERNAME' has been created successfully with sudo/wheel privileges!"
echo ""
if [ -z "$SSH_KEY" ]; then
    echo "Next steps:"
    echo "1. Add your public SSH key to /home/$USERNAME/.ssh/authorized_keys"
    echo "2. Test SSH access: ssh $USERNAME@your-vm-ip"
    echo ""
    echo "To add your SSH key, you can either:"
    echo "- Copy it manually: echo 'your-public-key' >> /home/$USERNAME/.ssh/authorized_keys"
    echo "- Use ssh-copy-id: ssh-copy-id $USERNAME@your-vm-ip"
else
    echo "SSH key has been configured. You can now test SSH access:"
    echo "ssh $USERNAME@your-vm-ip"
fi
