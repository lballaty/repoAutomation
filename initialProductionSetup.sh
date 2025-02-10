#!/bin/bash

# Define source and destination directories
SOURCE_DIR="/Users/liborballaty/Documents/Projects/GitHubProjectsDocuments"
DEST_DIR="/Users/liborballaty/Documents/Projects/Production"

# Create the destination directory if it doesn't exist
mkdir -p "$DEST_DIR"

# Copy directory structure only (no files)
rsync -a -f"+ */" -f"- *" "$SOURCE_DIR/" "$DEST_DIR/"

# Copy only software source files, excluding unnecessary files
rsync -av \
    --exclude=".git/" --exclude="*.md" --exclude="__pycache__" \
    --exclude=".DS_Store" --exclude="*.log" --exclude="*.tmp" --exclude="*.swp" \
    --exclude="docs/" --exclude=".vscode/" --exclude=".idea/" \
    --exclude=".swiftpm/" --exclude=".build/" --exclude="DerivedData/" --exclude="*.xcworkspace" --exclude="*.xcodeproj" \
    --exclude=".dart_tool/" --exclude=".flutter-plugins/" --exclude="build/" --exclude=".packages" --exclude="pubspec.lock" --exclude=".metadata/" \
    --exclude="CMakeFiles/" --exclude="CMakeCache.txt" --exclude="*.o" --exclude="*.a" --exclude="*.so" --exclude="*.dylib" --exclude="*.exe" --exclude="*.obj" --exclude=".vs/" \
    --exclude="node_modules/" --exclude=".next/" --exclude="dist/" --exclude="build/" --exclude=".cache/" --exclude=".npm/" --exclude="package-lock.json" --exclude="yarn.lock" \
    --exclude="*.sqlite" --exclude="*.db" --exclude="*.db-journal" --exclude="pg_data/" --exclude=".supabase/" --exclude="supabase/.temp/" \
    "$SOURCE_DIR/" "$DEST_DIR/"

echo "Software files copied to $DEST_DIR without Git metadata, dependencies, build artifacts, or unnecessary files."

