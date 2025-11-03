#!/bin/bash
# sync-develop.sh
# Syncs develop branch from master
#
# Usage:
#   ./scripts/sync-develop.sh
#   git sync-develop  (if alias configured)
#
# Description:
#   Safely merges latest master into develop branch and pushes to remote.
#   Handles merge conflicts gracefully and provides clear instructions.

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Emoji support (fallback for terminals without emoji support)
if [[ "$TERM" == *"xterm"* ]] || [[ "$TERM" == *"screen"* ]]; then
    EMOJI_SYNC="🔄"
    EMOJI_CHECK="✅"
    EMOJI_ERROR="❌"
    EMOJI_WARNING="⚠️"
    EMOJI_PACKAGE="📦"
    EMOJI_DOWNLOAD="📥"
    EMOJI_UPLOAD="📤"
    EMOJI_MERGE="🔀"
    EMOJI_PARTY="🎉"
else
    EMOJI_SYNC="[SYNC]"
    EMOJI_CHECK="[OK]"
    EMOJI_ERROR="[ERROR]"
    EMOJI_WARNING="[WARN]"
    EMOJI_PACKAGE="[PKG]"
    EMOJI_DOWNLOAD="[DOWN]"
    EMOJI_UPLOAD="[UP]"
    EMOJI_MERGE="[MERGE]"
    EMOJI_PARTY="[DONE]"
fi

# Function to print colored output
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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Main function
main() {
    echo ""
    print_info "$EMOJI_SYNC Syncing develop from master..."
    echo ""

    # Check if git is installed
    if ! command_exists git; then
        print_error "$EMOJI_ERROR Git is not installed"
        exit 1
    fi

    # Check if we're in a git repository
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        print_error "$EMOJI_ERROR Not a git repository"
        print_info "Please run this script from within a git repository"
        exit 1
    fi

    # Get repository root
    REPO_ROOT=$(git rev-parse --show-toplevel)
    print_info "Repository: $REPO_ROOT"

    # Check if develop branch exists locally
    if ! git rev-parse --verify develop >/dev/null 2>&1; then
        print_warning "$EMOJI_WARNING Develop branch doesn't exist locally"

        # Check if it exists remotely
        if git ls-remote --exit-code --heads origin develop >/dev/null 2>&1; then
            print_info "Fetching develop from remote..."
            git fetch origin develop:develop
        else
            print_error "$EMOJI_ERROR Develop branch doesn't exist remotely"
            print_info "Create it with: git checkout -b develop && git push -u origin develop"
            exit 1
        fi
    fi

    # Check if master branch exists
    if ! git ls-remote --exit-code --heads origin master >/dev/null 2>&1; then
        print_error "$EMOJI_ERROR Master branch doesn't exist remotely"
        exit 1
    fi

    # Save current branch
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    print_info "Current branch: $CURRENT_BRANCH"

    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        print_warning "$EMOJI_WARNING You have uncommitted changes"
        read -p "Do you want to continue? (y/n) " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Aborted by user"
            exit 0
        fi
    fi

    # Fetch latest master
    print_info "$EMOJI_DOWNLOAD Fetching latest master from remote..."
    if ! git fetch origin master; then
        print_error "$EMOJI_ERROR Failed to fetch master"
        exit 1
    fi
    print_success "$EMOJI_CHECK Master fetched"

    # Switch to develop
    print_info "$EMOJI_PACKAGE Checking out develop branch..."
    if ! git checkout develop; then
        print_error "$EMOJI_ERROR Failed to checkout develop"
        exit 1
    fi

    # Pull latest develop
    print_info "$EMOJI_DOWNLOAD Pulling latest develop..."
    if ! git pull origin develop; then
        print_warning "$EMOJI_WARNING Failed to pull develop (might not exist on remote)"
        # Continue anyway, develop might be a new branch
    fi

    # Check how far behind develop is from master
    BEHIND_COUNT=$(git rev-list --count develop..origin/master 2>/dev/null || echo "0")
    if [[ "$BEHIND_COUNT" -eq "0" ]]; then
        print_success "$EMOJI_CHECK Develop is already up to date with master!"
        git checkout "$CURRENT_BRANCH"
        echo ""
        print_info "$EMOJI_PARTY Nothing to sync. You're all set!"
        exit 0
    fi

    print_info "$EMOJI_MERGE Develop is $BEHIND_COUNT commits behind master"
    print_info "Merging master into develop..."
    echo ""

    # Attempt merge
    if git merge origin/master -m "chore: sync develop with master"; then
        print_success "$EMOJI_CHECK Merge successful!"

        # Push to remote
        print_info "$EMOJI_UPLOAD Pushing to origin/develop..."
        if git push origin develop; then
            print_success "$EMOJI_CHECK Pushed successfully!"
            echo ""
            print_success "$EMOJI_PARTY Develop synced successfully!"

            # Show summary
            echo ""
            print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            print_info "Summary:"
            print_info "  • Merged $BEHIND_COUNT commits from master"
            print_info "  • Develop is now up to date"
            print_info "  • Changes pushed to origin/develop"
            print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
        else
            print_error "$EMOJI_ERROR Failed to push to origin/develop"
            print_info "You may need to:"
            print_info "  1. Check your network connection"
            print_info "  2. Verify you have push access to origin/develop"
            print_info "  3. Try pushing manually: git push origin develop"
            git checkout "$CURRENT_BRANCH"
            exit 1
        fi
    else
        # Merge conflict detected
        print_error "$EMOJI_ERROR Merge conflict detected!"
        echo ""
        print_warning "Conflicting files:"
        git diff --name-only --diff-filter=U | while read -r file; do
            echo "  • $file"
        done
        echo ""

        print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        print_info "How to resolve:"
        print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        print_info "1. Resolve conflicts in the files listed above"
        print_info "   Edit each file and look for conflict markers:"
        print_info "   <<<<<<< HEAD"
        print_info "   ======="
        print_info "   >>>>>>> origin/master"
        echo ""
        print_info "2. After resolving, stage the files:"
        print_info "   ${GREEN}git add .${NC}"
        echo ""
        print_info "3. Commit the resolution:"
        print_info "   ${GREEN}git commit -m \"fix: resolve develop sync conflicts\"${NC}"
        echo ""
        print_info "4. Push to remote:"
        print_info "   ${GREEN}git push origin develop${NC}"
        echo ""
        print_warning "Or abort the merge:"
        print_info "   ${YELLOW}git merge --abort${NC}"
        print_info "   ${YELLOW}git checkout $CURRENT_BRANCH${NC}"
        echo ""
        print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""

        # Don't auto-abort, leave in conflicted state for user to resolve
        print_warning "Merge conflict needs manual resolution"
        print_info "You are now on the develop branch with conflicts"
        exit 1
    fi

    # Return to original branch
    if [[ "$CURRENT_BRANCH" != "develop" ]]; then
        print_info "Returning to $CURRENT_BRANCH..."
        git checkout "$CURRENT_BRANCH"
    fi

    echo ""
    print_success "$EMOJI_PARTY All done!"
}

# Run main function
main "$@"
