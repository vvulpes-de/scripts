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
    - [👤 create\_user\_with\_sudo.sh](#-create_user_with_sudosh)
  - [📝 License](#-license)

## 🔧 Requirements

- Bash 4.0 or higher
- Standard Unix utilities (ssh-keygen, adduser, etc.)
- Root access for user creation scripts

## 📂 Scripts Overview

| Script | Description |
|--------|-------------|
| `generate_ssh_key.sh` | Generate SSH key pairs with safety checks and customization options |
| `create_user_with_sudo.sh` | Create new users with sudo privileges and SSH key setup |

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

### 👤 create_user_with_sudo.sh

Creates new users with sudo privileges and optional SSH key setup for server administration.

**Features:**
- ✅ User creation with sudo/wheel privileges
- ✅ Automatic SSH directory setup
- ✅ SSH key installation support
- ✅ Cross-distribution compatibility (Ubuntu/CentOS/RHEL)
- ✅ Safety checks for existing users

**Usage:**
```bash
# Must be run as root
sudo ./create_user_with_sudo.sh <username> [ssh_public_key]
```

**Examples:**
```bash
# Create user without SSH key
sudo ./create_user_with_sudo.sh devuser

# Create user with SSH key
sudo ./create_user_with_sudo.sh devuser "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGx... user@example.com"
```

**What it does:**
1. Creates a new user account
2. Adds user to sudo/wheel group (depending on distribution)
3. Sets up SSH directory with correct permissions
4. Optionally installs provided SSH public key
5. Provides next steps for SSH access


## 📝 License

This project is licensed under the terms specified in the [LICENSE](LICENSE) file.




---

**Note:** Always review scripts before running them, especially those requiring root privileges.
