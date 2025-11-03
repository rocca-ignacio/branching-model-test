#!/bin/bash
# install-aliases.sh
# One-command setup for git aliases
#
# Usage:
#   ./scripts/install-aliases.sh
#
# Description:
#   Installs helpful git aliases for the branching model workflow.
#   Can install globally (all repos) or locally (this repo only).

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Emoji support
if [[ "$TERM" == *"xterm"* ]] || [[ "$TERM" == *"screen"* ]]; then
    EMOJI_ROCKET="🚀"
    EMOJI_CHECK="✅"
    EMOJI_INFO="ℹ️"
    EMOJI_QUESTION="❓"
    EMOJI_WRENCH="🔧"
    EMOJI_PARTY="🎉"
else
    EMOJI_ROCKET="[GO]"
    EMOJI_CHECK="[OK]"
    EMOJI_INFO="[INFO]"
    EMOJI_QUESTION="[?]"
    EMOJI_WRENCH="[TOOL]"
    EMOJI_PARTY="[DONE]"
fi

print_info() {
    echo -e "${BLUE}${1}${NC}"
}

print_success() {
    echo -e "${GREEN}${1}${NC}"
}

print_error() {
    echo -e "${RED}${1}${NC}"
}

print_warning() {
    echo -e "${YELLOW}${1}${NC}"
}

print_header() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${GREEN}${1}${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# Check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        print_error "$EMOJI_ERROR Not a git repository"
        print_info "Please run this script from within the repository"
        exit 1
    fi
}

# Get script directory
get_script_dir() {
    if [[ -f "scripts/sync-develop.sh" ]]; then
        echo "$(pwd)/scripts/sync-develop.sh"
    else
        # Try to find it relative to this script
        SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
        if [[ -f "$SCRIPT_DIR/sync-develop.sh" ]]; then
            echo "$SCRIPT_DIR/sync-develop.sh"
        else
            print_error "$EMOJI_ERROR Cannot find sync-develop.sh script"
            print_info "Expected location: ./scripts/sync-develop.sh"
            exit 1
        fi
    fi
}

# Install git alias
install_git_alias() {
    local scope=$1  # "global" or "local"
    local script_path=$2

    if [[ "$scope" == "global" ]]; then
        FLAG="--global"
        SCOPE_NAME="globally (all repositories)"
    else
        FLAG="--local"
        SCOPE_NAME="locally (this repository only)"
    fi

    print_info "$EMOJI_WRENCH Installing git aliases $SCOPE_NAME..."
    echo ""

    # Install sync-develop alias
    git config $FLAG alias.sync-develop "!bash '$script_path'"
    print_success "$EMOJI_CHECK Installed: git sync-develop"

    # Install short alias
    git config $FLAG alias.sd "!bash '$script_path'"
    print_success "$EMOJI_CHECK Installed: git sd (short alias)"

    # Install status alias with sync reminder
    # This shows sync status when on master
    git config $FLAG alias.sync-status "!bash -c 'CURRENT=\$(git rev-parse --abbrev-ref HEAD); if [[ \$CURRENT == \"master\" ]]; then BEHIND=\$(git rev-list --count develop..origin/master 2>/dev/null || echo \"?\"); if [[ \$BEHIND != \"0\" && \$BEHIND != \"?\" ]]; then echo \"⚠️  Develop is \$BEHIND commits behind master. Run: git sync-develop\"; fi; fi'"
    print_success "$EMOJI_CHECK Installed: git sync-status (checks if sync needed)"

    echo ""
}

# Show usage instructions
show_usage() {
    print_header "$EMOJI_PARTY Installation Complete!"

    print_info "Available commands:"
    echo ""
    echo "  ${GREEN}git sync-develop${NC}  - Sync develop branch from master"
    echo "  ${GREEN}git sd${NC}             - Short alias for sync-develop"
    echo "  ${GREEN}git sync-status${NC}    - Check if develop needs syncing"
    echo ""

    print_info "Example workflow:"
    echo ""
    echo "  1. After merging PR to master:"
    echo "     ${BLUE}git checkout master${NC}"
    echo "     ${BLUE}git pull${NC}"
    echo "     ${BLUE}git sync-develop${NC}"
    echo ""

    echo "  2. Or use the short version:"
    echo "     ${BLUE}git checkout master && git pull && git sd${NC}"
    echo ""

    echo "  3. Check sync status anytime:"
    echo "     ${BLUE}git sync-status${NC}"
    echo ""

    print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_info "For more details, see: docs/git-alias-guide.md"
    print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# Show installed aliases
show_current_aliases() {
    local scope=$1

    if [[ "$scope" == "global" ]]; then
        FLAG="--global"
    else
        FLAG="--local"
    fi

    echo ""
    print_info "Currently installed aliases ($scope):"
    echo ""

    # Check for sync-develop
    if ALIAS=$(git config $FLAG --get alias.sync-develop 2>/dev/null); then
        echo "  ${GREEN}✓${NC} git sync-develop → $ALIAS"
    else
        echo "  ${YELLOW}✗${NC} git sync-develop (not installed)"
    fi

    # Check for sd
    if ALIAS=$(git config $FLAG --get alias.sd 2>/dev/null); then
        echo "  ${GREEN}✓${NC} git sd → $ALIAS"
    else
        echo "  ${YELLOW}✗${NC} git sd (not installed)"
    fi

    # Check for sync-status
    if ALIAS=$(git config $FLAG --get alias.sync-status 2>/dev/null); then
        echo "  ${GREEN}✓${NC} git sync-status → (installed)"
    else
        echo "  ${YELLOW}✗${NC} git sync-status (not installed)"
    fi

    echo ""
}

# Main installation flow
main() {
    print_header "$EMOJI_ROCKET Git Alias Installer for Branching Model"

    # Check if in git repo
    check_git_repo

    # Find sync-develop.sh script
    SCRIPT_PATH=$(get_script_dir)
    print_success "$EMOJI_CHECK Found sync script: $SCRIPT_PATH"

    # Verify script is executable
    if [[ ! -x "$SCRIPT_PATH" ]]; then
        print_warning "$EMOJI_INFO Making script executable..."
        chmod +x "$SCRIPT_PATH"
    fi

    # Show current aliases (local)
    show_current_aliases "local"

    # Show current aliases (global)
    show_current_aliases "global"

    # Ask user for installation scope
    echo ""
    print_info "$EMOJI_QUESTION Installation scope:"
    echo ""
    echo "  1) Local  - Install aliases for this repository only"
    echo "  2) Global - Install aliases for all your git repositories"
    echo "  3) Both   - Install both local and global aliases"
    echo "  4) Cancel"
    echo ""
    read -p "Choose an option (1-4): " -n 1 -r CHOICE
    echo ""
    echo ""

    case $CHOICE in
        1)
            install_git_alias "local" "$SCRIPT_PATH"
            show_usage
            ;;
        2)
            install_git_alias "global" "$SCRIPT_PATH"
            show_usage
            ;;
        3)
            install_git_alias "local" "$SCRIPT_PATH"
            install_git_alias "global" "$SCRIPT_PATH"
            show_usage
            ;;
        4)
            print_info "Installation cancelled"
            exit 0
            ;;
        *)
            print_error "$EMOJI_ERROR Invalid option"
            exit 1
            ;;
    esac

    # Test the installation
    print_info "$EMOJI_CHECK Testing installation..."
    if git config --get alias.sync-develop >/dev/null 2>&1; then
        print_success "$EMOJI_PARTY Aliases installed successfully!"
    else
        print_error "$EMOJI_ERROR Something went wrong with installation"
        exit 1
    fi
}

# Run main function
main "$@"
