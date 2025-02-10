#!/bin/bash

# Define local repository directory
LOCAL_REPOS_DIR="/Users/liborballaty/Documents/Projects/GitHubProjectsDocuments"

# Define log file location
LOG_FILE="$LOCAL_REPOS_DIR/sync_log.txt"

# Ensure the directory exists
if [ ! -d "$LOCAL_REPOS_DIR" ]; then
    echo "Error: Directory $LOCAL_REPOS_DIR does not exist." | tee -a "$LOG_FILE"
    exit 1
fi

# Change to the local repo directory
cd "$LOCAL_REPOS_DIR" || exit

echo "🚀 Starting sync process: $(date)" | tee -a "$LOG_FILE"
echo "--------------------------------------" | tee -a "$LOG_FILE"

# Loop through each repo in the local directory
for REPO in */; do
    # Remove trailing slash from repo name
    REPO=${REPO%/}

    echo "🔍 Checking repository: $REPO" | tee -a "$LOG_FILE"
    cd "$LOCAL_REPOS_DIR/$REPO" || continue

    # Check for uncommitted changes
    if [[ -n $(git status --porcelain) ]]; then
        echo "📝 Uncommitted changes detected in $REPO. Committing them..." | tee -a "$LOG_FILE"
        git add . && git commit -m "Auto-commit: Syncing local changes before pull" | tee -a "$LOG_FILE"
    fi

    # Fetch latest changes from remote
    git fetch origin | tee -a "$LOG_FILE"

    # Check if local branch is ahead, behind, or has conflicts
    LOCAL_STATUS=$(git status -sb)

    if [[ "$LOCAL_STATUS" == *"[ahead"* ]]; then
        echo "⬆️  Pushing committed changes for $REPO..." | tee -a "$LOG_FILE"
        git push origin main 2>&1 | tee -a "$LOG_FILE"
        if [[ $? -ne 0 ]]; then
            echo "⚠️  Error pushing $REPO. Check manually." | tee -a "$LOG_FILE"
        fi
    fi

    if [[ "$LOCAL_STATUS" == *"[behind"* ]]; then
        echo "⬇️  Pulling latest changes for $REPO..." | tee -a "$LOG_FILE"
        git pull --rebase origin main 2>&1 | tee -a "$LOG_FILE"
        if [[ $? -ne 0 ]]; then
            echo "⚠️  Merge conflict detected in $REPO! Skipping sync." | tee -a "$LOG_FILE"
            cd "$LOCAL_REPOS_DIR"
            continue
        fi
    fi

    echo "✅  $REPO is up to date." | tee -a "$LOG_FILE"
    cd "$LOCAL_REPOS_DIR"
    echo "--------------------------------------" | tee -a "$LOG_FILE"
done

echo "🎉 Sync completed: $(date)" | tee -a "$LOG_FILE"
echo "🚀 Check log file at: $LOG_FILE"

