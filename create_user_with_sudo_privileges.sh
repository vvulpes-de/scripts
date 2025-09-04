#!/usr/bin/env bash
#------------------------------------------------------------------------------
# create_user_with_sudo_privileges.sh
#
# Creates a user with sudo privileges.
#
# Usage:
#   sudo ./create_user_with_sudo_privileges.sh [--user <username>] [--key <ssh_public_key>] [--key-file <path>] [--dry-run]
#
# Examples:
#   sudo ./create_user_with_sudo_privileges.sh --user admin
#   sudo ./create_user_with_sudo_privileges.sh --user myuser --key "ssh-rsa AAAAB3NzaC1y..."
#   sudo ./create_user_with_sudo_privileges.sh --user admin --key-file ~/.ssh/id_rsa.pub
#   sudo ./create_user_with_sudo_privileges.sh --user admin --dry-run
#
# Notes:
# - Creates a user with sudo privileges
# - Optionally sets up SSH key authentication
#------------------------------------------------------------------------------

set -Eeuo pipefail

# --------------------------- Config / Defaults -------------------------------
readonly DEFAULT_USERNAME="admin"
USERNAME="$DEFAULT_USERNAME"
SSH_PUBLIC_KEY=""
SSH_KEY_FILE=""
DRY_RUN=0

# ------------------------------ Logging --------------------------------------
if [[ -t 1 ]]; then  # Only use colors if output is to terminal
    readonly COLOR_GREEN="\033[1;32m"
    readonly COLOR_YELLOW="\033[1;33m"
    readonly COLOR_RED="\033[1;31m"
    readonly COLOR_BLUE="\033[1;34m"
    readonly COLOR_CYAN="\033[1;36m"
    readonly COLOR_RESET="\033[0m"
else
    readonly COLOR_GREEN=""
    readonly COLOR_YELLOW=""
    readonly COLOR_RED=""
    readonly COLOR_BLUE=""
    readonly COLOR_CYAN=""
    readonly COLOR_RESET=""
fi

log_info()    { echo -e "${COLOR_GREEN}[INFO]${COLOR_RESET} $*"; }
log_warn()    { echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} $*"; }
log_error()   { echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $*" >&2; }
log_debug()   { echo -e "${COLOR_BLUE}[DEBUG]${COLOR_RESET} $*"; }
log_success() { echo -e "${COLOR_CYAN}[SUCCESS]${COLOR_RESET} $*"; }

# ------------------------------ Helpers --------------------------------------
usage() {
    cat <<EOF
Usage: sudo $0 [OPTIONS]

Creates a user with sudo privileges and optionally sets up SSH key authentication.

Options:
  --user <username>             Username to create (default: $DEFAULT_USERNAME)
  --key <ssh_public_key>        SSH public key string to add
  --key-file <path>             Path to SSH public key file to add
  --dry-run                     Show what would be done without making changes
  -h, --help                    Show this help

Examples:
  sudo $0 --user admin
  sudo $0 --user myuser --key "ssh-rsa AAAAB3NzaC1y..."
  sudo $0 --user admin --key-file ~/.ssh/id_rsa.pub
  sudo $0 --user admin --dry-run

Notes:
  - Creates user with sudo privileges for administrative access
  - Optionally sets up SSH key authentication for secure access
  - Validates SSH key format if provided
EOF
}

ensure_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        log_error "Please run as root (use sudo)."
        exit 1
    fi
}

validate_username() {
    if [[ ! "$USERNAME" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
        log_error "Invalid username: '$USERNAME'. Must start with letter/underscore, contain only lowercase letters, numbers, hyphens, underscores."
        exit 1
    fi
    
    if [[ ${#USERNAME} -gt 32 ]]; then
        log_error "Username too long: '$USERNAME' (max 32 characters)."
        exit 1
    fi
}

user_exists() {
    getent passwd "$USERNAME" >/dev/null 2>&1
}

validate_ssh_key() {
    local key="$1"
    if [[ -z "$key" ]]; then
        return 1
    fi
    
    # Basic SSH key format validation
    if [[ "$key" =~ ^(ssh-rsa|ssh-dss|ssh-ed25519|ecdsa-sha2-) ]]; then
        return 0
    else
        log_error "Invalid SSH key format. Key must start with ssh-rsa, ssh-dss, ssh-ed25519, or ecdsa-sha2-"
        return 1
    fi
}

read_key_file() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        log_error "SSH key file not found: $file"
        exit 1
    fi
    
    if [[ ! -r "$file" ]]; then
        log_error "Cannot read SSH key file: $file (permission denied)"
        exit 1
    fi
    
    local key_content
    key_content=$(cat "$file" | tr -d '\n\r')
    
    if ! validate_ssh_key "$key_content"; then
        log_error "Invalid SSH key in file: $file"
        exit 1
    fi
    
    echo "$key_content"
}

create_user() {
    log_info "Creating user '$USERNAME' with sudo privileges..."
    
    if user_exists; then
        log_warn "User '$USERNAME' already exists."
        return 0
    fi
    
    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY-RUN] Would create user '$USERNAME' with sudo privileges"
        return 0
    fi
    
    # Create user with home directory and bash shell
    useradd -m -s /bin/bash -G sudo "$USERNAME"
    log_success "Created user '$USERNAME' with sudo privileges"
}

set_user_password() {
    if user_exists && [[ $DRY_RUN -eq 0 ]]; then
        log_warn "Setting password for '$USERNAME'..."
        echo
        passwd "$USERNAME"
        echo
        log_info "Password set for '$USERNAME'."
    elif [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY-RUN] Would prompt for password for user '$USERNAME'"
    fi
}

setup_user_ssh() {
    local home_dir="/home/$USERNAME"
    local ssh_dir="$home_dir/.ssh"
    local auth_keys="$ssh_dir/authorized_keys"
    
    log_info "Setting up SSH configuration for user '$USERNAME'..."
    
    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY-RUN] Would create SSH directory: $ssh_dir"
        log_info "[DRY-RUN] Would set directory permissions: 700"
        log_info "[DRY-RUN] Would set ownership: $USERNAME:$USERNAME"
        if [[ -n "$SSH_PUBLIC_KEY" ]]; then
            log_info "[DRY-RUN] Would add SSH public key to: $auth_keys"
        fi
        return 0
    fi
    
    # Create SSH directory
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"
    chown "$USERNAME:$USERNAME" "$ssh_dir"
    log_debug "Created SSH directory: $ssh_dir"
    
    # Add SSH public key if provided
    if [[ -n "$SSH_PUBLIC_KEY" ]]; then
        echo "$SSH_PUBLIC_KEY" > "$auth_keys"
        chmod 600 "$auth_keys"
        chown "$USERNAME:$USERNAME" "$auth_keys"
        log_success "Added SSH public key for user '$USERNAME'"
    else
        log_warn "No SSH public key provided for user '$USERNAME'"
        log_warn "You can add an SSH key manually later:"
        echo "  sudo nano $auth_keys"
        echo "  sudo chmod 600 $auth_keys"
        echo "  sudo chown $USERNAME:$USERNAME $auth_keys"
    fi
}

setup_root_ssh() {
    # Root SSH setup is optional for this script
    # Focus is on creating the user with sudo privileges
    return 0
}

validate_ssh_setup() {
    local home_dir="/home/$USERNAME"
    local user_auth_keys="$home_dir/.ssh/authorized_keys"
    
    log_info "Validating SSH setup for user '$USERNAME'..."
    
    # Check user SSH keys
    if [[ -f "$user_auth_keys" && -s "$user_auth_keys" ]]; then
        local user_key_count
        user_key_count=$(grep -c -E '^(ssh-|ecdsa-|ed25519)' "$user_auth_keys" 2>/dev/null || echo "0")
        if [[ "$user_key_count" -gt 0 ]]; then
            log_success "User '$USERNAME' has $user_key_count SSH key(s) configured"
        else
            log_warn "User '$USERNAME' authorized_keys file exists but contains no valid SSH keys"
        fi
    else
        log_info "User '$USERNAME' has no SSH keys configured"
    fi
    
    return 0
}

show_next_steps() {
    echo
    log_success "User creation completed successfully!"
    echo
    log_info "User '$USERNAME' has been created with:"
    echo "  ✅ Home directory: /home/$USERNAME"
    echo "  ✅ Sudo privileges"
    echo "  ✅ Bash shell"
    if [[ -n "$SSH_PUBLIC_KEY" ]]; then
        echo "  ✅ SSH key authentication configured"
    else
        echo "  ⚠️  No SSH key configured (password authentication only)"
    fi
    echo
    log_info "You can now:"
    echo "  • Log in as: $USERNAME"
    echo "  • Use sudo for administrative tasks"
    if [[ -n "$SSH_PUBLIC_KEY" ]]; then
        echo "  • Connect via SSH using your private key"
    fi
    echo
}

show_summary() {
    log_info "Configuration Summary:"
    log_info "  Target user: $USERNAME"
    log_info "  SSH key provided: $([ -n "$SSH_PUBLIC_KEY" ] && echo "Yes" || echo "No")"
    if [[ -n "$SSH_KEY_FILE" ]]; then
        log_info "  SSH key file: $SSH_KEY_FILE"
    fi
    log_info "  User will have sudo privileges: Yes"
    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "  Mode: DRY RUN (no changes will be made)"
    fi
    echo
}

# ------------------------------- Argument Parsing -------------------------------
parse_arguments() {
    if [[ $# -eq 0 ]]; then
        # No arguments is OK, use defaults
        return 0
    fi
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --user)
                if [[ -z "${2:-}" ]]; then
                    log_error "--user requires a value"
                    exit 1
                fi
                USERNAME="$2"
                shift 2
                ;;
            --key)
                if [[ -z "${2:-}" ]]; then
                    log_error "--key requires a value"
                    exit 1
                fi
                SSH_PUBLIC_KEY="$2"
                shift 2
                ;;
            --key-file)
                if [[ -z "${2:-}" ]]; then
                    log_error "--key-file requires a value"
                    exit 1
                fi
                SSH_KEY_FILE="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown argument: $1"
                usage
                exit 1
                ;;
        esac
    done
}

validate_arguments() {
    validate_username
    
    # If key file is provided, read it
    if [[ -n "$SSH_KEY_FILE" ]]; then
        if [[ -n "$SSH_PUBLIC_KEY" ]]; then
            log_error "Cannot specify both --key and --key-file"
            exit 1
        fi
        SSH_PUBLIC_KEY=$(read_key_file "$SSH_KEY_FILE")
    fi
    
    # Validate SSH key if provided
    if [[ -n "$SSH_PUBLIC_KEY" ]]; then
        if ! validate_ssh_key "$SSH_PUBLIC_KEY"; then
            exit 1
        fi
    fi
}

# ------------------------------- Main ----------------------------------------
main() {
    # Set up error handling
    trap 'log_error "An error occurred during user creation."; exit 1' ERR
    
    parse_arguments "$@"
    ensure_root
    validate_arguments
    
    show_summary
    
    if user_exists && [[ $DRY_RUN -eq 0 ]]; then
        log_warn "User '$USERNAME' already exists. Updating configuration..."
        echo
    fi
    
    create_user
    
    # Set password for the user
    set_user_password
    
    setup_user_ssh
    
    if [[ $DRY_RUN -eq 0 ]]; then
        validate_ssh_setup
        show_next_steps
    else
        log_info "[DRY-RUN] All validation checks would be performed"
        echo
        log_info "[DRY-RUN] User creation completed successfully"
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi