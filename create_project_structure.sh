#!/bin/bash

# Set the base directory where the project should be created
BASE_DIR="/Users/liborballaty/Documents/Projects/GitHubProjectsDocuments"

# Check if the user provided a project name
if [ -z "$1" ]; then
    echo "Usage: $0 <project-name>"
    exit 1
fi

# Set the project directory
PROJECT_NAME=$1
PROJECT_DIR="$BASE_DIR/$PROJECT_NAME"

# Ensure the base directory exists
if [ ! -d "$BASE_DIR" ]; then
    echo "Error: Base directory '$BASE_DIR' does not exist."
    exit 1
fi

# Check if the project directory already exists
if [ -d "$PROJECT_DIR" ]; then
    echo "⚠️  Warning: The project directory '$PROJECT_DIR' already exists."
    echo "Choose an option:"
    echo "  [1] Add missing folders only (keep existing files unchanged)"
    echo "  [2] Overwrite everything (backup & delete first)"
    echo "  [3] Cancel"
    read -p "Enter your choice (1/2/3): " USER_CHOICE

    if [[ "$USER_CHOICE" == "3" ]]; then
        echo "Operation cancelled."
        exit 0
    elif [[ "$USER_CHOICE" == "2" ]]; then
        # Confirm again before overwriting
        read -p "Are you sure? This will backup & delete all existing files in '$PROJECT_DIR' (y/n): " CONFIRM2
        if [[ "$CONFIRM2" != "y" ]]; then
            echo "Operation cancelled."
            exit 0
        fi

        # Create a timestamped backup before deletion
        TIMESTAMP=$(date +%Y%m%d-%H%M%S)
        BACKUP_FILE="$BASE_DIR/${PROJECT_NAME}_backup_$TIMESTAMP.tar.gz"
        echo "📦 Creating backup of existing directory..."
        tar -czf "$BACKUP_FILE" -C "$BASE_DIR" "$PROJECT_NAME"
        echo "✅ Backup saved as '$BACKUP_FILE'."

        # Remove the existing directory after backup
        rm -rf "$PROJECT_DIR"
        echo "🗑️  Existing directory '$PROJECT_DIR' has been removed."

    elif [[ "$USER_CHOICE" != "1" ]]; then
        echo "❌ Invalid choice. Operation cancelled."
        exit 1
    fi
fi

# Define the directory structure
DIRECTORIES=(
    "$PROJECT_DIR/.github/workflows"
    "$PROJECT_DIR/docs/poc"
    "$PROJECT_DIR/src/app/(auth)"
    "$PROJECT_DIR/src/app/(wizard)"
    "$PROJECT_DIR/src/app/(dashboard)"
    "$PROJECT_DIR/src/app/api"
    "$PROJECT_DIR/src/components/ui"
    "$PROJECT_DIR/src/components/wizard"
    "$PROJECT_DIR/src/components/forms"
    "$PROJECT_DIR/src/components/shared"
    "$PROJECT_DIR/src/lib/supabase"
    "$PROJECT_DIR/src/lib/openai"
    "$PROJECT_DIR/src/lib/utils"
    "$PROJECT_DIR/src/styles"
    "$PROJECT_DIR/public"
    "$PROJECT_DIR/tests/unit"
    "$PROJECT_DIR/tests/integration"
    "$PROJECT_DIR/src/services"
    "$PROJECT_DIR/src/middleware"
    "$PROJECT_DIR/src/config"
    "$PROJECT_DIR/database/migrations"
)

# Create missing directories
for dir in "${DIRECTORIES[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        echo "📂 Created: $dir"
    fi
done

# Function to create files with default content
create_file() {
    local file_path="$1"
    local content="$2"
    
    if [ ! -f "$file_path" ]; then
        echo -e "$content" > "$file_path"
        echo "📄 Created: $file_path"
    fi
}

# Create necessary files with boilerplate content
create_file "$PROJECT_DIR/.gitignore" "node_modules/\n.env\n.logs/\n.next/\nout/\n.vscode/\n.idea/\n.DS_Store"
create_file "$PROJECT_DIR/README.md" "# $PROJECT_NAME\n\nThis project is a compliance automation platform built with Next.js, Supabase, and AI."
create_file "$PROJECT_DIR/.env.example" "NEXT_PUBLIC_SUPABASE_URL=your-supabase-url\nNEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key\n\nOPENAI_API_KEY=your-openai-key"
create_file "$PROJECT_DIR/package.json" "{\n  \"name\": \"$PROJECT_NAME\",\n  \"version\": \"1.0.0\",\n  \"description\": \"A compliance automation platform.\",\n  \"scripts\": {\n    \"dev\": \"next dev\",\n    \"build\": \"next build\",\n    \"start\": \"next start\",\n    \"lint\": \"eslint .\"\n  },\n  \"dependencies\": {\n    \"next\": \"^13.4.0\",\n    \"react\": \"^18.2.0\",\n    \"react-dom\": \"^18.2.0\",\n    \"supabase\": \"^1.0.0\",\n    \"openai\": \"^3.0.0\"\n  }\n}"
create_file "$PROJECT_DIR/tsconfig.json" "{\n  \"compilerOptions\": {\n    \"target\": \"esnext\",\n    \"module\": \"esnext\",\n    \"jsx\": \"preserve\",\n    \"strict\": true,\n    \"moduleResolution\": \"node\",\n    \"resolveJsonModule\": true\n  }\n}"
create_file "$PROJECT_DIR/.eslintrc.json" "{\n  \"extends\": [\"next/core-web-vitals\"]\n}"
create_file "$PROJECT_DIR/.prettierrc" "{\n  \"singleQuote\": true,\n  \"semi\": false\n}"
create_file "$PROJECT_DIR/src/lib/supabase/client.ts" "import { createClient } from '@supabase/supabase-js';\n\nconst supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || '';\nconst supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '';\n\nexport const supabase = createClient(supabaseUrl, supabaseAnonKey);"
create_file "$PROJECT_DIR/src/lib/openai/index.ts" "import { Configuration, OpenAIApi } from 'openai';\n\nconst configuration = new Configuration({ apiKey: process.env.OPENAI_API_KEY });\nexport const openai = new OpenAIApi(configuration);"
create_file "$PROJECT_DIR/src/config/index.ts" "export const APP_CONFIG = {\n  appName: \"Compliance Automation\",\n  apiBaseUrl: process.env.NEXT_PUBLIC_API_BASE_URL || \"http://localhost:3000\"\n};"
create_file "$PROJECT_DIR/docs/poc/README.md" "# Proof of Concept Documentation\n\nThis directory contains documentation for POC features."
create_file "$PROJECT_DIR/database/migrations/README.md" "# Database Migrations\n\nThis directory contains database migration scripts for schema updates."

# Initialize a Git repository (optional)
if [ ! -d "$PROJECT_DIR/.git" ]; then
    read -p "Do you want to initialize a Git repository? (y/n): " INIT_GIT
    if [[ "$INIT_GIT" == "y" ]]; then
        cd "$PROJECT_DIR" || exit
        git init
        echo "✅ Git repository initialized."
        cd ..
    fi
fi

# Print success message
echo "🎉 Project structure for '$PROJECT_NAME' created successfully at '$PROJECT_DIR'."

