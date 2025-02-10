Asks if you want a dry run first

If yes, it previews changes without modifying files.
If no, it proceeds with copying/deleting as needed.
Syncs new and existing repositories

Adds missing repos to Production.
Copies modified files into existing directories.
Detects orphaned repositories in Production

If a repo exists in Production but not in GitHubProjectsDocuments, it asks before deleting.
Logs all actions

Saves details of additions, updates, and deletions in sync_production.log.

