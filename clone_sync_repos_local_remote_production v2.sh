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
# 9. Delete repositories listed in an external file
# 10. Handle protected branches and uncommitted changes
# 11. Log file size check and alerts for batch mode

# ========== COLOR DEFINITIONS ==========
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
BLUE="\e[34m"
RESET="\e[0m"

# ========== CONFIGURATION ==========
# Choose a centralized logs folder outside your repos
LOG_DIR="$HOME/Documents/Projects/sync_logs"
mkdir -p "$LOG_DIR"

# Define the production directory path
PRODUCTION_DIR="$HOME/Documents/Projects/Production"

# Define the archive directory inside Production
ARCHIVE_DIR="$PRODUCTION_DIR/Archived"

#---------------Log files------------- 
UNCOMMITTED_FILE="$LOG_DIR/uncommitted_changes.txt"
LOG_FILE="$LOG_DIR/sync_log.txt"
DELETE_LIST_FILE="$LOG_DIR/repos_to_delete.txt"

LOCAL_REPOS_FILE="$LOG_DIR/local_repos_list.txt"


GITHUB_REPOS_FILE="$LOG_DIR/github_repos_list.txt"

LOCAL_REPOS_DIR="$HOME/Documents/Projects/GitHubProjectsDocuments"
REPOS_TO_SKIP=()


BATCH_MODE=false
MAX_LOG_SIZE=10485760  # 10MB log file size limit


# ========== FUNCTION: LOGGING & ALERTS ==========
log_action() {
    printf "%s - %s\n" "$(date +'%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG_FILE"
}

alert() {
    printf "${RED}❌ %s ALERT: %s${RESET}\n" "$(date +'%Y-%m-%d %H:%M:%S')" "$*" \
        | tee -a "$LOG_FILE"
}

success() {
    printf "${GREEN}✅ %s SUCCESS: %s${RESET}\n" "$(date +'%Y-%m-%d %H:%M:%S')" "$*" \
        | tee -a "$LOG_FILE"
}

warning() {
    printf "${YELLOW}⚠️  %s WARNING: %s${RESET}\n" "$(date +'%Y-%m-%d %H:%M:%S')" "$*" \
        | tee -a "$LOG_FILE"
}

info() {
    printf "${BLUE}ℹ️  %s INFO: %s${RESET}\n" "$(date +'%Y-%m-%d %H:%M:%S')" "$*" \
        | tee -a "$LOG_FILE"
}

error() {
    printf "${RED}❌ %s ERROR: %s${RESET}\n" "$(date +'%Y-%m-%d %H:%M:%S')" "$*" \
        | tee -a "$LOG_FILE"
}

GITHUB_USER="lballaty"
#GITHUB_PAT="REDACTED_TOKEN_REVOKED"

if [[ -f "$LOCAL_REPOS_DIR/repoAutomation/.github_token" ]]; then
    GITHUB_PAT=$(<"$LOCAL_REPOS_DIR/repoAutomation/.github_token")
else
    echo -e "${RED}❌ ERROR: GitHub token file not found. Please create the token file at $LOCAL_REPOS_DIR/repoAutomation/.github_token${RESET}"
    exit 1
fi


# Ensure the directories exist
if [[ ! -d "$PRODUCTION_DIR" ]]; then
    info "Production directory does not exist. Creating it now..."
    mkdir -p "$PRODUCTION_DIR"
    mkdir -p "$ARCHIVE_DIR"
    success "Production directory and archive folder created successfully."
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${RED}❌ ERROR: 'jq' is required but not installed. Please install it and try again.${RESET}" | tee -a "$LOG_FILE"
    exit 1
fi

# Cache GitHub repository list once for the entire script execution.
info "Caching GitHub repository list..."
GITHUB_REPOS_CACHE=$(curl -s -H "Authorization: token $GITHUB_PAT" "https://api.github.com/user/repos?per_page=100" | jq -r '.[].name' | tr '[:upper:]' '[:lower:]' | sort)
if [[ -z "$GITHUB_REPOS_CACHE" ]]; then
    alert "Failed to retrieve GitHub repository list."
    exit 1
else
    success "GitHub repository list cached successfully."
fi




info "Using GitHub account: $GITHUB_USER"

# ========== CHECK ENVIRONMENT VARIABLES ==========
if [[ -z "$GITHUB_PAT" ]]; then
    echo "❌ ERROR: GITHUB_PAT is not set. Please set it in your environment variables." | tee -a "$LOG_FILE"
    exit 1
fi


# ========== RETRIEVE AND SAVE REPOSITORY LISTS ==========
info "Fetching list of local repositories..."
find "$LOCAL_REPOS_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | tr '[:upper:]' '[:lower:]' | sort > "$LOCAL_REPOS_FILE"
info "Local repository list stored in $LOCAL_REPOS_FILE."

info "Fetching list of GitHub repositories..."
curl -s -H "Authorization: token $GITHUB_PAT" "https://api.github.com/user/repos?per_page=100" | jq -r '.[].name' | tr '[:upper:]' '[:lower:]' | sort > "$GITHUB_REPOS_FILE"
info "GitHub repository list stored in $GITHUB_REPOS_FILE."



# ========== FUNCTION: CHECK LOG FILE SIZE ==========
check_log_size() {
    info "Checking log file size..."
    if [[ -f "$LOG_FILE" ]]; then
        LOG_SIZE=$(wc -c < "$LOG_FILE")
        info "Current log file size: ${LOG_SIZE} bytes"
        if (( LOG_SIZE > MAX_LOG_SIZE )); then
            warning "Log file exceeded $MAX_LOG_SIZE bytes."
            if [ "$BATCH_MODE" = true ]; then
                TIMESTAMP=$(date +'%Y%m%d%H%M%S')
                # Create a backup copy of the current log file.
                cp "$LOG_FILE" "${LOG_FILE}.${TIMESTAMP}.backup"
                success "Log file backed up as: ${LOG_FILE}.${TIMESTAMP}.backup"
                # Optionally, if you want to start fresh, uncomment the next line.
                # : > "$LOG_FILE"
                #
                # If you prefer to preserve all logs continuously, leave the file intact.
                #
            else
                warning "Consider rotating logs manually."
            fi
        fi
    else
        info "No existing log file found. A new one will be created."
    fi
}



# ========== CHECK GITHUB AUTHENTICATION ==========
check_github_auth() {
    info "Checking GitHub authentication for $GITHUB_USER..."
    API_RESPONSE=$(curl -s -H "Authorization: token $GITHUB_PAT" https://api.github.com/user)
    API_USERNAME=$(echo "$API_RESPONSE" | jq -r .login)

    if [[ -z "$API_USERNAME" || "$API_USERNAME" == "null" ]]; then
        alert "GitHub authentication failed for user: $GITHUB_USER."
        exit 1
    else
        success "GitHub authentication successful for user: $API_USERNAME."
    fi
}

check_github_auth  # Ensure authentication works before proceeding


# ========== FUNCTION: DISPLAY HELP ==========
display_help() {
    echo -e "${BLUE}GitHub & Production Sync Manager - Usage Guide${RESET}\n"
    echo "Usage: $0 [OPTIONS]"
    echo -e "\nOptions:"
    echo "  --batch               Run in batch mode (no interactive prompts)"
    echo "  --help                Display this help message"
    echo -e "\nFeatures:"
    echo "  1. Check and clone missing repositories from GitHub"
    echo "  2. Create missing repositories in GitHub from local"
    echo "  3. Sync local repositories with GitHub"
    echo "  4. Sync the production environment"
    echo "  5. Detect and archive orphaned production repositories"
    echo "  6. Handle conflicts by creating backup branches"
    echo "  7. Ensure safe deletion of repositories listed in an external file"
    echo "  8. Handle protected branches and uncommitted changes"
    echo "  9. Log file size check and alerts for batch mode"
    echo -e "\nExample:"
    echo "  $0 --batch      Run all operations in batch mode"
    echo "  $0 --help       Display this help message"
    #exit 0
    success "\e[42mFinished function: <help function>.\e[0m"

}

# ========== FUNCTION: CHECK GITHUB FOR REPO MAIN PROTECTION ==========

is_protected_branch() {
    local repo_name="$1"
    # Get branch information for 'main' branch from GitHub
    local branch_info
    branch_info=$(curl -s -H "Authorization: token $GITHUB_PAT" "https://api.github.com/repos/$GITHUB_USER/$repo_name/branches/main")
    # Extract the "protected" field (expected to be "true" or "false")
    echo "$branch_info" | jq -r '.protected'
}


# ========== FUNCTION: PARSE ARGUMENTS ==========
for arg in "$@"; do
    case $arg in
        --help)
            display_help
            ;;
        --batch)
            BATCH_MODE=true
            ;;
    esac
done


# ========== FUNCTION: check local repo uncommitted changes ==========

check_uncommitted_changes() {
    info "\e[42mStarting function: check_uncommitted_changes...\e[0m"
    info "Looking for uncommitted changes in local repositories..."

    # File to record all repos & their uncommitted changes
    #UNCOMMITTED_FILE="uncommitted_changes.txt"
    # Overwrite (or create) a fresh file
    : > "$UNCOMMITTED_FILE"

    # A flag to track if the user wants to ignore all changes (skip everything)
    IGNORE_ALL_CHANGES=false

    for REPO in "$LOCAL_REPOS_DIR"/*/; do
        [[ ! -d "$REPO/.git" ]] && continue  # skip if not a Git repo

        REPO_NAME=$(basename "$REPO")
        #cd "$REPO" || continue
        pushd "$REPO" > /dev/null || continue
        # ... operations in repo ...


        CHANGES=$(git status --porcelain)
        popd > /dev/null

        if [[ -n "$CHANGES" ]]; then
            # If user already chose to ignore all changes, just skip
            if [[ "$IGNORE_ALL_CHANGES" == "true" ]]; then
                warning "Auto-skipping '$REPO_NAME' due to previously selected 'Ignore All'."
                REPOS_TO_SKIP+=("$REPO_NAME")
                continue
            fi

            warning "⚠️ Local repository '$REPO_NAME' has uncommitted changes."

            # Show what's changed
            git status

            # Log details to file
            {
                echo "=== $REPO_NAME ==="
                echo "$CHANGES"
                echo
            } >> "$UNCOMMITTED_FILE"

            # Prompt: commit, stash, ignore this one, ignore all, or abort

if [ "$BATCH_MODE" = true ]; then
    # In batch mode, default to ignoring uncommitted changes
    warning "Batch mode active: Automatically ignoring uncommitted changes in '$REPO_NAME'."
    echo "Ignored uncommitted changes in '$REPO_NAME' due to batch mode." >> "$UNCOMMITTED_FILE"
    REPOS_TO_SKIP+=("$REPO_NAME")
else
    read -p "(C)ommit, (S)tash, (I)gnore, (G)Ignore All, or (A)bort for '$REPO_NAME'? " ANSWER
    case "$ANSWER" in
        [Cc] )
            git add .
            COMMIT_MSG="Auto-commit by script at $(date +'%Y-%m-%d %H:%M:%S')"
            if git commit -m "$COMMIT_MSG"; then
                success "Committed changes in '$REPO_NAME'."
            else
                warning "Commit failed in '$REPO_NAME'. Skipping sync."
                REPOS_TO_SKIP+=("$REPO_NAME")
            fi
            ;;
        [Ss] )
            if git stash; then
                success "Stashed changes in '$REPO_NAME'."
            else
                warning "Stash failed in '$REPO_NAME'. Skipping sync."
                REPOS_TO_SKIP+=("$REPO_NAME")
            fi
            ;;
        [Ii] )
            warning "Ignoring changes in '$REPO_NAME'—sync will be skipped."
            REPOS_TO_SKIP+=("$REPO_NAME")
            ;;
        [Gg] )
            warning "User chose 'Ignore All'. Skipping '$REPO_NAME' and all further repos."
            REPOS_TO_SKIP+=("$REPO_NAME")
            IGNORE_ALL_CHANGES=true
            ;;
        [Aa] )
            alert "Aborting script due to uncommitted changes in '$REPO_NAME'."
            exit 1
            ;;
        * )
            warning "Unrecognized choice; ignoring '$REPO_NAME' and skipping sync."
            REPOS_TO_SKIP+=("$REPO_NAME")
            ;;
    esac
fi
fi

    done

    if [[ ${#REPOS_TO_SKIP[@]} -gt 0 ]]; then
        info "Uncommitted changes found in ${#REPOS_TO_SKIP[@]} repo(s). Details in '$UNCOMMITTED_FILE'."
        warning "Those repos will be skipped during sync."
    else
        info "No uncommitted changes found in any local repository."
    fi

    success "\e[42mFinished function: check_uncommitted_changes.\e[0m"
}



# ========== FUNCTION: SYNC LOCAL REPOSITORIES WITH GITHUB ==========
sync_local_with_github() {
    info "\e[42mStarting function: sync_local_with_github...\e[0m"
    info "Syncing local repositories with GitHub..."

    # File to record any directories that are NOT Git repos
NON_GIT_REPOS_FILE="$LOG_DIR/non_git_repos.txt"

# Overwrite (or create) the file to start fresh
: > "$NON_GIT_REPOS_FILE"

# Iterate over every subdirectory in LOCAL_REPOS_DIR
for REPO in "$LOCAL_REPOS_DIR"/*/; do
    # Skip if this is not a directory (e.g., if it doesn't exist)
    [[ ! -d "$REPO" ]] && continue

    # Check if the directory has a .git subfolder
    if [[ ! -d "$REPO/.git" ]]; then
        REPO_NAME=$(basename "$REPO")
        warning "⚠️  Directory '$REPO_NAME' is NOT a Git repository."

        # Prompt user for action
        read -p "Do you want to initialize a Git repository here? (y/n): " CONFIRM

        if [[ "$CONFIRM" == "y" ]]; then
            pushd "$REPO" > /dev/null || continue
            git init
            success "✅ Initialized Git repository in '$REPO_NAME'."
            popd > /dev/null
            continue #skip the rest of the loop for this iteration
        else
            echo "$REPO_NAME" >> "$NON_GIT_REPOS_FILE"
            warning "Skipping initialization of '$REPO_NAME'."
            continue # Skip this directory from further processing.
        fi
    fi





        
        # This directory *is* a Git repo; proceed with Git ops
          
             pushd "$REPO" > /dev/null || continue

                # If it's in REPOS_TO_SKIP, don't sync
        if [[ " ${REPOS_TO_SKIP[@]} " =~ " $REPO_NAME " ]]; then
            warning "Skipping $REPO_NAME due to uncommitted changes."
            popd > /dev/null
            continue
        fi



        git fetch origin
        LOCAL_STATUS=$(git status -sb)

if [[ "$LOCAL_STATUS" == *"[ahead"* ]]; then
    info "Repository '$REPO_NAME' is ahead of remote. Checking if 'main' is protected..."
    if [[ "$(is_protected_branch "$REPO_NAME")" == "true" ]]; then
        warning "Branch 'main' in '$REPO_NAME' is protected. Skipping push to avoid conflicts."
    else
        if git push origin main; then
            success "Successfully pushed changes for '$REPO_NAME'."
        else
            alert "Failed to push changes for '$REPO_NAME'."
            popd > /dev/null
            echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: Failed to push changes for '$REPO_NAME'." >> "$LOG_DIR/push_errors_log.txt"
        fi
    fi
fi


        
# Inside the loop in sync_local_with_github, after fetching and getting LOCAL_STATUS
if [[ "$LOCAL_STATUS" == *"[behind"* ]]; then
    info "Pulling latest changes for $REPO_NAME..."
    if ! git pull --rebase origin main; then
        alert "Merge conflict detected in $REPO_NAME! Attempting to create a backup branch."
        CONFLICT_BRANCH="conflict_backup_${REPO_NAME}_$(date +%Y%m%d%H%M%S)"
        if git checkout -b "$CONFLICT_BRANCH"; then
            echo "[$(date +'%Y-%m-%d %H:%M:%S')] Conflict backup branch '$CONFLICT_BRANCH' created for '$REPO_NAME'." >> "$LOG_DIR/conflicts_log.txt"
            success "Backup branch '$CONFLICT_BRANCH' created for $REPO_NAME."
        else
            alert "Failed to create backup branch for $REPO_NAME."
        fi
    fi
fi

        
        success "$REPO_NAME is up to date."
        popd > /dev/null
    done
    
    info "Non-Git directories have been recorded in $NON_GIT_REPOS_FILE."
    success "\e[42mFinished function: sync_local_with_github.\e[0m"
}


# ========== FUNCTION: CHECK & ARCHIVE ORPHANED REPOSITORIES ==========
handle_orphaned_production_repos() {
    info "\e[42mStarting function: handle_orphaned_production_repos...\e[0m"
    info "Checking for orphaned repositories in Production..."
    mkdir -p "$ARCHIVE_DIR"  # Ensure our archive folder exists

    for REPO in "$PRODUCTION_DIR"/*/; do
        REPO_NAME=$(basename "$REPO")
        
        # Skip the archive folder itself
        if [[ "$REPO_NAME" == "Archived" ]]; then
            continue
        fi

        # Check if it's orphaned:
        #  1) Not found locally, AND
        #  2) Not found in the cached list of GitHub repos
        if [[ ! -d "$LOCAL_REPOS_DIR/$REPO_NAME" ]] && ! echo "$GITHUB_REPOS_CACHE" | grep -qw "$REPO_NAME"; then
            warning "Orphaned repository detected: $REPO_NAME"
            read -p "Do you want to archive it? (y/n): " CONFIRM

            if [[ "$CONFIRM" == "y" ]]; then
                mv "$REPO" "$ARCHIVE_DIR/$REPO_NAME"
                success "Archived orphaned repository: $REPO_NAME"
            else
                warning "Skipped archiving of orphaned repository: $REPO_NAME"
            fi
        fi
    done
    success "\e[42mFinished function: handle_orphaned_production_repos.\e[0m"
}



# ========== FUNCTION: CHECK & CLONE MISSING REPOSITORIES FROM GITHUB ==========

check_and_clone_github_repos() {
    info "\e[42mStarting function: <check_and_clone_github_repos>...\e[0m"
    info "Checking for missing repositories in GitHub..."

    # Fetch the list of GitHub repositories
    #GITHUB_REPOS=$(curl -s -H "Authorization: token $GITHUB_PAT" "https://api.github.com/user/repos?per_page=100" | jq -r '.[].name' | tr '[:upper:]' '[:lower:]' | sort)
    GITHUB_REPOS="$GITHUB_REPOS_CACHE"
    info "Fetched GitHub repositories:"

    # Fetch the list of local repositories
    LOCAL_REPOS=$(find "$LOCAL_REPOS_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | tr '[:upper:]' '[:lower:]' | sort)
    info "Local repositories: "

    # Function to check if a GitHub repository exists
    github_repo_exists() {
        local repo_name=$1
        local response=$(curl -s -o /dev/null -w "%{http_code}" "https://api.github.com/repos/$GITHUB_USER/$repo_name")
        
        if [[ "$response" -eq 200 ]]; then
            return 0  # Repository exists
        elif [[ "$response" -eq 403 ]]; then
            warning "API rate limit exceeded or no permission for '$repo_name'."
            return 2
        else
            return 1  # Repository does not exist
        fi
    }

    # Iterate over each GitHub repository
    for REPO in $GITHUB_REPOS; do
        if [[ ! -d "$LOCAL_REPOS_DIR/$REPO/.git" ]]; then
            github_repo_exists "$REPO"
            EXISTS_STATUS=$?
            if [[ $EXISTS_STATUS -eq 0 ]]; then
                info "Repository '$REPO' not found locally. Cloning..."
                git clone "https://$GITHUB_USER:$GITHUB_PAT@github.com/$GITHUB_USER/$REPO.git" "$LOCAL_REPOS_DIR/$REPO"
                if [[ $? -eq 0 ]]; then
                    success "Successfully cloned repository: $REPO"
                else
                    error "Failed to clone repository: $REPO"
                fi
            elif [[ $EXISTS_STATUS -eq 2 ]]; then
                warning "Skipping '$REPO' due to API limit or permission issue."
            else
                warning "Repository '$REPO' does not exist on GitHub. Skipping..."
            fi
        fi
    done

    success "Finished function: check_and_clone_github_repos."
}



# ========== FUNCTION: CREATE MISSING REPOSITORIES ON GITHUB ==========
create_missing_github_repos() {
    info "\e[42mStarting function: <create_missing_github_repos>...\e[0m"
    info "Checking for local repositories missing in GitHub..."

    # Fetch the list of GitHub repositories into an array
    # Instead of mapfile -t ...
# Use cached GitHub repository list to build the array.
if [ -n "$GITHUB_REPOS_CACHE" ]; then
    # Read the cached data into an array, splitting on newlines.
    IFS=$'\n' read -d '' -r -a GITHUB_REPOS_ARR <<< "$GITHUB_REPOS_CACHE"
else
    # Fallback: If for some reason the cache is empty, initialize an empty array.
    GITHUB_REPOS_ARR=()
fi


    info "Fetched GitHub repositories "
    #printf '%s\n' "${GITHUB_REPOS_ARR[@]}"

    # Fetch the list of local repositories into an array
    LOCAL_REPOS_ARR=()
    while IFS= read -r line; do
        LOCAL_REPOS_ARR+=("$line")
    done < <(
        find "$LOCAL_REPOS_DIR" -mindepth 1 -maxdepth 1 -type d \
        -exec basename {} \; \
        | tr '[:upper:]' '[:lower:]' \
        | sort
    )

    info "Local repositories"
    #printf '%s\n' "${LOCAL_REPOS_ARR[@]}"

    # Iterate over each local repository
    for REPO in "${LOCAL_REPOS_ARR[@]}"; do
        REPO_FOUND=false
        for REMOTE_REPO in "${GITHUB_REPOS_ARR[@]}"; do
            if [[ "$REPO" == "$REMOTE_REPO" ]]; then
                REPO_FOUND=true
                break
            fi
        done
        
        if [ "$REPO_FOUND" = false ]; then
            warning "Local repo '$REPO' is missing in GitHub. Creating now..."
            # Create the repository on GitHub
            RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
                       -H "Authorization: token $GITHUB_PAT" \
                       -d "{\"name\": \"$REPO\"}" \
                       "https://api.github.com/user/repos")
            
            if [[ $RESPONSE -eq 201 ]]; then
                success "Successfully created repository '$REPO' on GitHub."
            elif [[ $RESPONSE -eq 422 ]]; then
                error "Failed to create repository '$REPO': A repository with this name already exists on your GitHub account."
            else
                error "Failed to create repository '$REPO': HTTP status code $RESPONSE."
            fi
        else
            info "Repository '$REPO' already exists on GitHub. Skipping creation."
        fi
    done

    success "\e[42mFinished function: <create_missing_github_repos>.\e[0m"
}


# ========== FUNCTION: DELETE REPOSITORIES ==========
delete_repositories() {
    info "\e[42mStarting function: delete_repositories...\e[0m"
    
    if [[ ! -f "$DELETE_LIST_FILE" ]]; then
        warning "No delete list file found. Skipping repository deletion."
        return
    fi

    if [[ ! -s "$DELETE_LIST_FILE" ]]; then
        warning "Delete list file is empty. Skipping repository deletion."
        return
    fi

    info "Reading repositories to delete from $DELETE_LIST_FILE..."
    while IFS= read -r REPO_NAME || [[ -n "$REPO_NAME" ]]; do
        warning "Repository '$REPO_NAME' is marked for deletion."
        
        # In batch mode, default to deletion without prompting.
        if [ "$BATCH_MODE" = true ]; then
            CONFIRM="y"
        else
            read -p "Are you sure you want to delete '$REPO_NAME'? (y/n): " CONFIRM
        fi

        if [[ "$CONFIRM" == "y" ]]; then
            # Remove local directories
            rm -rf "$LOCAL_REPOS_DIR/$REPO_NAME"
            rm -rf "$PRODUCTION_DIR/$REPO_NAME"
            
            # Attempt deletion on GitHub and capture the HTTP status code
            HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE -H "Authorization: token $GITHUB_PAT" "https://api.github.com/repos/$GITHUB_USER/$REPO_NAME")
            if [[ "$HTTP_CODE" == "204" ]]; then
                success "Deleted repository: $REPO_NAME"
            else
                error "Failed to delete repository '$REPO_NAME' on GitHub. HTTP status code: $HTTP_CODE"
            fi
        else
            warning "Skipped deletion of repository: $REPO_NAME"
        fi
    done < "$DELETE_LIST_FILE"
    
    success "\e[42mFinished function: delete_repositories.\e[0m"
}




# ========== MAIN EXECUTION ==========

check_log_size
check_github_auth
check_and_clone_github_repos
create_missing_github_repos
check_uncommitted_changes
sync_local_with_github
handle_orphaned_production_repos
delete_repositories

success "All operations completed."
