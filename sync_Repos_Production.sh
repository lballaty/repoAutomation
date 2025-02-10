#!/bin/bash

# Define source and destination directories
SOURCE_DIR="/Users/liborballaty/Documents/Projects/GitHubProjectsDocuments"
DEST_DIR="/Users/liborballaty/Documents/Projects/Production"
LOG_FILE="sync_production.log"

# Function to log actions
log_action() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Ask for dry run mode
echo "🔍 Would you like to do a dry run first? (y/n)"
read -r DRY_RUN_CHOICE

if [[ "$DRY_RUN_CHOICE" == "y" ]]; then
    DRY_RUN="--dry-run"
    log_action "Dry run mode selected."
else
    DRY_RUN=""
    log_action "Running in normal mode."
fi

# Ensure the destination directory exists
mkdir -p "$DEST_DIR"

log_action "Starting synchronization..."

# Sync directory structure: Add new directories but don't copy files yet
rsync -a $DRY_RUN -f"+ */" -f"- *" "$SOURCE_DIR/" "$DEST_DIR/"

# Find all Git repositories in the source directory
find "$SOURCE_DIR" -type d -name ".git" | while read -r GIT_DIR; do
    REL_PATH="${GIT_DIR#$SOURCE_DIR/}"   # Get relative path of the repo
    REPO_DIR="$(dirname "$REL_PATH")"    # Get the parent directory of .git
    PROD_REPO_DIR="$DEST_DIR/$REPO_DIR"  # Corresponding path in Production

    # Ensure the directory exists in Production
    mkdir -p "$PROD_REPO_DIR"

    # Copy only software files, including modified ones
    rsync -av $DRY_RUN \
        --exclude=".git/" --exclude="*.md" --exclude="__pycache__" \
        --exclude=".DS_Store" --exclude="*.log" --exclude="*.tmp" --exclude="*.swp" \
        --exclude="docs/" --exclude=".vscode/" --exclude=".idea/" \
        --exclude=".swiftpm/" --exclude=".build/" --exclude="DerivedData/" --exclude="*.xcworkspace" --exclude="*.xcodeproj" \
        --exclude=".dart_tool/" --exclude=".flutter-plugins/" --exclude="build/" --exclude=".packages" --exclude="pubspec.lock" --exclude=".metadata/" \
        --exclude="CMakeFiles/" --exclude="CMakeCache.txt" --exclude="*.o" --exclude="*.a" --exclude="*.so" --exclude="*.dylib" --exclude="*.exe" --exclude="*.obj" --exclude=".vs/" \
        --exclude="node_modules/" --exclude=".next/" --exclude="dist/" --exclude="build/" --exclude=".cache/" --exclude=".npm/" --exclude="package-lock.json" --exclude="yarn.lock" \
        --exclude="*.sqlite" --exclude="*.db" --exclude="*.db-journal" --exclude="pg_data/" --exclude=".supabase/" --exclude="supabase/.temp/" \
        "$SOURCE_DIR/$REPO_DIR/" "$PROD_REPO_DIR/"

    log_action "Updated: $PROD_REPO_DIR"
done

log_action "Checking for orphaned repositories in Production..."

# Find top-level directories in Production that don't exist in Source
find "$DEST_DIR" -mindepth 1 -maxdepth 1 -type d | while read -r PROD_DIR; do
    REPO_NAME="$(basename "$PROD_DIR")"
    
    if [[ ! -d "$SOURCE_DIR/$REPO_NAME" ]]; then
        echo "⚠️  Warning: The repository '$REPO_NAME' exists in Production but not in GitHubProjectsDocuments."
        read -p "Do you want to delete '$PROD_DIR' and all its contents? (y/n) " choice
        if [[ "$choice" == "y" ]]; then
            rm -rf "$PROD_DIR"
            log_action "Deleted orphaned repository: $PROD_DIR"
            echo "🗑️  Deleted '$PROD_DIR'."
        else
            log_action "Skipped deletion of orphaned repository: $PROD_DIR"
            echo "❌ Skipped deletion of '$PROD_DIR'."
        fi
    fi
done

log_action "Synchronization complete. Production directory is now up to date!"
echo "🎯 Sync complete! Check '$LOG_FILE' for details."

