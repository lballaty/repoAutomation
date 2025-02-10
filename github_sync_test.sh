#!/bin/bash

# Set GitHub username
GITHUB_USER="lballaty"

# Use stored token (if using environment variable)
TOKEN="$GITHUB_PAT"

# Fetch list of your repositories
curl -H "Authorization: token $TOKEN" -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/users/$GITHUB_USER/repos"

