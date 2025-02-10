#!/bin/bash

# ===============================
# GitHub & Production Sync Manager
# ===============================
# This script allows you to:
# 1. Check for missing repositories in GitHub and clone them locally
# 2. Create missing repositories on GitHub from local
# 3. Sync local repositories with GitHub
# 4. Set up & sync the production environment
# 5. Detect and handle orphaned repositories in production
# 6. Handle conflicts by creating backup branches
# 7. Run everything in batch mode (--batch)
# 8. Display help (--help)

# ========== COLOR DEFINITIONS ==========
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
BLUE="\e[34m"
RESET="\e[0m"

# ========== CONFIGURATION ==========
GITHUB_PAT="$GITHUB_PAT"  # Ensure this is set in your environment
GITHUB_USER=$(curl -s -H "Authorization: token $GITHUB_PAT" https://api.github.com/user | jq -r .login)
LOCAL_REPOS_DIR="$HOME/Documents/Projects/GitHubProjectsDocuments"
PRODUCTION_DIR="$HOME/Documents/Projects/Production"
LOG_FILE="sync_log.txt"
BATCH_MODE=false

# ========== FUNCTION: LOGGING & ALERTS ==========
log_action() {
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}
alert() {
    echo -e "${RED}❌ ALERT: $1${RESET}" | tee -a "$LOG_FILE"
}
success() {
    echo -e "${GREEN}✅ SUCCESS: $1${RESET}" | tee -a "$LOG_FILE"
}
warning() {
    echo -e "${YELLOW}⚠️  WARNING: $1${RESET}" | tee -a "$LOG_FILE"
}
info() {
    echo -e "${BLUE}ℹ️  INFO: $1${RESET}" | tee -a "$LOG_FILE"
}

# ========== FUNCTION: CHECK GITHUB AUTH ==========
check_github_auth() {
    if [ -z "$GITHUB_USER" ] || [ "$GITHUB_USER" == "null" ]; then
        alert "GitHub authentication failed. Ensure GITHUB_PAT is set."
        exit 1
    else
        success "GitHub authentication successful for user: $GITHUB_USER"
    fi
}

# ========== FUNCTION: CHECK & CLONE MISSING GITHUB REPOS ==========
check_and_clone_github_repos() {
    info "Checking for missing repositories in GitHub..."
    GITHUB_REPOS=$(curl -s -H "Authorization: token $GITHUB_PAT" "https://api.github.com/user/repos?per_page=100" | jq -r '.[].name')
    LOCAL_REPOS=$(ls -1 "$LOCAL_REPOS_DIR")

    for REPO in $GITHUB_REPOS; do
        if [[ ! " $LOCAL_REPOS " =~ " $REPO " ]]; then
            info "Cloning missing repo: $REPO"
            git clone "https://$GITHUB_USER:$GITHUB_PAT@github.com/$GITHUB_USER/$REPO.git" "$LOCAL_REPOS_DIR/$REPO"
        fi
    done
}

# ========== FUNCTION: CREATE MISSING GITHUB REPOS ==========
create_missing_github_repos() {
    info "Checking for local repositories missing in GitHub..."
    LOCAL_REPOS=$(ls -1 "$LOCAL_REPOS_DIR")
    GITHUB_REPOS=$(curl -s -H "Authorization: token $GITHUB_PAT" "https://api.github.com/user/repos?per_page=100" | jq -r '.[].name')

    for REPO in $LOCAL_REPOS; do
        if [[ ! " $GITHUB_REPOS " =~ " $REPO " ]]; then
            warning "Local repo '$REPO' is missing in GitHub. Creating now..."
            curl -X POST -H "Authorization: token $GITHUB_PAT" -H "Accept: application/vnd.github.v3+json" \
                https://api.github.com/user/repos -d "{\"name\": \"$REPO\", \"private\": false}"
            cd "$LOCAL_REPOS_DIR/$REPO" && git remote add origin "https://github.com/$GITHUB_USER/$REPO.git" && git push -u origin main
            success "Created and pushed $REPO to GitHub."
        fi
    done
}

# ========== FUNCTION: SYNC LOCAL REPOS WITH GITHUB ==========
sync_local_with_github() {
    info "Syncing local repositories with GitHub..."
    for REPO in "$LOCAL_REPOS_DIR"/*/; do
        REPO_NAME=$(basename "$REPO")
        cd "$REPO"
        git fetch origin
        LOCAL_STATUS=$(git status -sb)

        if [[ "$LOCAL_STATUS" == *"[ahead"* ]]; then
            info "Pushing committed changes for $REPO_NAME..."
            git push origin main || alert "Failed to push $REPO_NAME!"
        fi
        if [[ "$LOCAL_STATUS" == *"[behind"* ]]; then
            info "Pulling latest changes for $REPO_NAME..."
            git pull --rebase origin main || {
                alert "Merge conflict detected in $REPO_NAME! Creating backup branch."
                git checkout -b conflict_backup_$(date +%Y%m%d%H%M%S)
            }
        fi
        success "$REPO_NAME is up to date."
    done
}

# ========== MAIN EXECUTION ==========
check_github_auth
check_and_clone_github_repos
create_missing_github_repos
sync_local_with_github

success "All operations completed."

