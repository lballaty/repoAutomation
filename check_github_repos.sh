#!/bin/bash

# Ensure the GitHub token is set
if [ -z "$GITHUB_PAT" ]; then
    echo "Error: GITHUB_PAT is not set. Please export it first."
    exit 1
fi

# Get the authenticated GitHub username
GITHUB_USER=$(curl -s -H "Authorization: token $GITHUB_PAT" https://api.github.com/user | jq -r .login)

if [ -z "$GITHUB_USER" ]; then
    echo "Error: Could not fetch GitHub username. Check your token."
    exit 1
fi

# Fetch GitHub repositories
echo "Fetching GitHub repositories..."
GITHUB_REPOS=$(curl -s -H "Authorization: token $GITHUB_PAT" "https://api.github.com/user/repos?per_page=100" | jq -r '.[].name')

echo "Your GitHub repositories:"
echo "$GITHUB_REPOS"
echo "-----------------------------"

# Define local repository folder (modify if needed)
LOCAL_REPOS_DIR="/Users/liborballaty/Documents/Projects/GitHubProjectsDocuments"
#mkdir -p "$LOCAL_REPOS_DIR"

# Get a list of local repositories
echo "Checking local repositories in $LOCAL_REPOS_DIR..."
LOCAL_REPOS=$(ls -1 "$LOCAL_REPOS_DIR" 2>/dev/null)

# Compare GitHub repos with local ones
for REPO in $GITHUB_REPOS; do
    if [[ ! " $LOCAL_REPOS " =~ " $REPO " ]]; then
        echo "Cloning missing repo: $REPO"
        git clone "https://$GITHUB_USER:$GITHUB_PAT@github.com/$GITHUB_USER/$REPO.git" "$LOCAL_REPOS_DIR/$REPO"
    else
        echo "Repo exists locally: $REPO"
    fi
done

# Display all repositories (local & GitHub)
echo "-----------------------------"
echo "Final List of Local Repositories:"
ls -1 "$LOCAL_REPOS_DIR"

