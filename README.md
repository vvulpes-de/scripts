# Scripts

A collection of useful bash scripts for system administration and development tasks.

## 📋 Table of Contents

- [Scripts](#scripts)
  - [📋 Table of Contents](#-table-of-contents)
  - [🔧 Requirements](#-requirements)
  - [📂 Scripts Overview](#-scripts-overview)
  - [🚀 Installation](#-installation)
    - [Option 1: Clone the entire repository (Recommended)](#option-1-clone-the-entire-repository-recommended)
    - [Option 2: Download individual scripts](#option-2-download-individual-scripts)
  - [💡 Usage](#-usage)
  - [📖 Scripts Documentation](#-scripts-documentation)
    - [🔐 generate\_ssh\_key.sh](#-generate_ssh_keysh)
    - [👤 create\_user\_with\_sudo\_privileges.sh](#-create_user_with_sudo_privilegessh)
  - [📝 License](#-license)

## 🔧 Requirements

- Bash 4.0 or higher
- Standard Unix utilities (ssh-keygen, adduser, etc.)
- Root access for user creation scripts

## 📂 Scripts Overview

|#| Script | Description |
|--|--------|-------------|
|1| `generate_ssh_key.sh` | Generate SSH key pairs with safety checks and customization options |
|2| `create_user_with_sudo_privileges.sh` | Create new users with sudo privileges and SSH key setup |

## 🚀 Installation

### Option 1: Clone the entire repository (Recommended)

1. Clone this repository:
   ```bash
   git clone https://github.com/vvulpes-de/scripts.git
   cd scripts
   ```

2. Make all scripts executable:
   ```bash
   chmod +x *.sh
   ```

### Option 2: Download individual scripts

Download any script you need:
```bash
# Download a specific script using wget
wget https://raw.githubusercontent.com/vvulpes-de/scripts/main/<SCRIPT_NAME>.sh
# or using curl
curl -O <SCRIPT_NAME>.sh https://raw.githubusercontent.com/vvulpes-de/scripts/main/<SCRIPT_NAME>.sh

# Make it executable
chmod +x <SCRIPT_NAME>.sh

# Run the script
./<SCRIPT_NAME>.sh
```

## 💡 Usage

Each script can be run independently. Use the `-h` flag for help on scripts that support it.

## 📖 Scripts Documentation

### 🔐 generate_ssh_key.sh

A secure SSH key generator that prevents accidental overwrites and supports multiple key types.

**Features:**
- ✅ Automatic collision detection (won't overwrite existing keys)
- ✅ Support for multiple key types (ed25519, rsa, ecdsa)
- ✅ Custom key naming
- ✅ Comprehensive error handling
- ✅ Automatic unique filename generation

**Usage:**
```bash
# Basic usage with email (required)
./generate_ssh_key.sh -e user@example.com

# Custom key name
./generate_ssh_key.sh -e user@example.com -n my_github_key

# Different key type
./generate_ssh_key.sh -e user@example.com -n work_key -t rsa

# Show help
./generate_ssh_key.sh -h
```

**Parameters:**
- `-e EMAIL` (required): Email address for the key comment
- `-n NAME` (optional): Custom name for the key file (default: id_TYPE)
- `-t TYPE` (optional): Key type - ed25519, rsa, or ecdsa (default: ed25519)
- `-h`: Show help message

**Examples:**
```bash
# Generate a key for GitHub
./generate_ssh_key.sh -e john.doe@company.com -n github_key

# Generate an RSA key for legacy systems
./generate_ssh_key.sh -e admin@server.com -n legacy_server -t rsa
```
---
### 👤 create_user_with_sudo_privileges.sh

Creates new users with sudo privileges and optional SSH key setup for server administration.

**Features:**
- ✅ User creation with sudo privileges
- ✅ Automatic SSH directory setup
- ✅ SSH key installation support (inline key or key file)
- ✅ Username validation and safety checks
- ✅ Dry-run mode for testing
- ✅ Comprehensive error handling

**Usage:**
```bash
# Must be run as root
sudo ./create_user_with_sudo_privileges.sh [OPTIONS]
```

**Parameters:**
- `--user <username>`: Username to create (default: admin)
- `--key <ssh_public_key>`: SSH public key string to add
- `--key-file <path>`: Path to SSH public key file to add
- `--dry-run`: Show what would be done without making changes
- `-h, --help`: Show help message

**Examples:**
```bash
# Create user with default name 'admin'
sudo ./create_user_with_sudo_privileges.sh --user admin

# Create user with custom name
sudo ./create_user_with_sudo_privileges.sh --user myuser --key "ssh-rsa AAAAB3NzaC1y..."

# Create user and load SSH key from file
sudo ./create_user_with_sudo_privileges.sh --user admin --key-file ~/.ssh/id_rsa.pub

# Test what would be done (dry-run mode)
sudo ./create_user_with_sudo_privileges.sh --user admin --dry-run
```

**What it does:**
1. Creates a new user account with home directory
2. Adds user to sudo group for administrative privileges
3. Sets up SSH directory with correct permissions (700)
4. Optionally installs provided SSH public key
5. Sets user password (interactive prompt)
6. Validates SSH key format if provided


## 📝 License

This project is licensed under the terms specified in the [LICENSE](LICENSE) file.




---

**Note:** Always review scripts before running them, especially those requiring root privileges.
