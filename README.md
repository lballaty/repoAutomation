# repoAutomation - DEPRECATED

**⚠️ THIS REPOSITORY HAS BEEN CONSOLIDATED**

All tools from this repository have been moved to:

**📍 New Location:** `/Users/liborballaty/LocalProjects/GitHubProjectsDocuments/privateRepoTools`

**GitHub:** https://github.com/lballaty/privateRepoTools (PRIVATE)

## What Was Moved

**Repository Sync Tools:**
- Production environment sync scripts
- GitHub synchronization manager
- Repository status checker
- Python GitHub API viewer
- Project structure creator
- All archived script versions

**New Location:**
```
/Users/liborballaty/LocalProjects/GitHubProjectsDocuments/privateRepoTools/repo-sync/
```

## How to Use the Tools

```bash
# Navigate to the new location
cd /Users/liborballaty/LocalProjects/GitHubProjectsDocuments/privateRepoTools/repo-sync

# Sync to production environment
./sync_Repos_Production.sh

# Comprehensive GitHub sync
./github-sync-manager.sh

# Check GitHub repository status
export GITHUB_PAT="your_token"
./check_github_repos.sh

# Scan for sensitive data
./scan-repos-for-sensitive-data.sh

# Check repository visibility (public/private)
./check-repo-visibility.sh

# See full documentation
cat README.md
```

## Available Tools in New Location

**Primary Sync Scripts:**
- `sync_Repos_Production.sh` - Sync local repos to Production directory
- `github-sync-manager.sh` - Comprehensive GitHub/local/production sync
- `check_github_repos.sh` - Check GitHub repository status
- `github_repo_viewer.py` - Python-based GitHub API viewer
- `create_project_structure.sh` - Create standardized project structure
- `initialProductionSetup.sh` - First-time production environment setup

**New Security Tools:**
- `scan-repos-for-sensitive-data.sh` - Scan all repos for secrets, tokens, personal data
- `check-repo-visibility.sh` - Check if GitHub repos are public or private

**Archived Versions:**
- Old script versions preserved in `archive/` subdirectory

## Complete Documentation

See comprehensive guides at:
```
/Users/liborballaty/LocalProjects/GitHubProjectsDocuments/privateRepoTools/docs/
```

**Key Documents:**
- `README.md` - Main project documentation
- `repo-sync/README.md` - Detailed sync tools documentation
- `docs/SECURITY-SCAN-RESULTS.md` - Security audit results
- `docs/PURGE-PLAN.md` - Git history cleanup guide
- `CONSOLIDATION-SUMMARY.md` - Complete consolidation overview

## Why Consolidated?

RepoTools and repoAutomation had similar purposes (repository tooling). They have been consolidated into a single private repository to:
- Eliminate duplication
- Centralize all repository tools
- Improve organization and documentation
- Better security management
- Add new security scanning capabilities

## Security Note

This repository had its git history cleaned on 2025-10-17 to remove:
- Exposed GitHub token (now revoked)
- `.github_token` file
- Other sensitive data

The cleaned version is safe to use, but all active development has moved to privateRepoTools.

## Archive Date

**Consolidated:** 2025-10-17

**This repository is now archived and will not receive updates.**

For the latest tools, features, and documentation, use:
`/Users/liborballaty/LocalProjects/GitHubProjectsDocuments/privateRepoTools`

Questions: libor@arionetworks.com
