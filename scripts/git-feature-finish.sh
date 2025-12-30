#!/usr/bin/env bash
# Complete the feature workflow for the current feature/* branch.
# Steps:
#   1. Validate branch name (must be feature/*)
#   2. Ensure working tree is clean
#   3. Sync feature branch with latest origin/develop (calls git-feature-sync.sh)
#   4. (Optional) run tests
#   5. Merge feature into develop with --no-ff and push
#   6. Delete local and remote feature branch

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

current_branch=$(git rev-parse --abbrev-ref HEAD)

if [[ "$current_branch" != feature/* ]]; then
  echo "Error: git-feature-finish must be run from a feature/* branch (current: $current_branch)" >&2
  exit 1
fi

# Ensure working tree is clean
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Error: working tree not clean. Commit, stash, or discard changes before finishing the feature." >&2
  exit 1
fi

feature_branch="$current_branch"

echo "[git-feature-finish] Synchronizing feature branch with origin/develop..."
"$SCRIPT_DIR/git-feature-sync.sh"

# After sync, we should still be on the feature branch
current_branch_after_sync=$(git rev-parse --abbrev-ref HEAD)
if [[ "$current_branch_after_sync" != "$feature_branch" ]]; then
  echo "Error: expected to remain on $feature_branch after sync, but current branch is $current_branch_after_sync" >&2
  exit 1
fi

# Optional: run tests before merging into develop (left commented by default)
# echo "[git-feature-finish] Running tests before merge into develop..."
# astro dev pytest tests/ || { echo "[git-feature-finish] Tests failed. Aborting merge." >&2; exit 1; }

echo "[git-feature-finish] Updating local develop from origin/develop..."
git checkout develop
git pull origin develop

echo "[git-feature-finish] Merging feature branch $feature_branch into develop with --no-ff..."
git merge --no-ff "$feature_branch"

echo "[git-feature-finish] Pushing updated develop to origin..."
git push origin develop

echo "[git-feature-finish] Cleaning up feature branch $feature_branch..."
# Delete local branch (will fail if merge did not actually include all commits)
if git branch -d "$feature_branch"; then
  echo "[git-feature-finish] Deleted local branch $feature_branch."
else
  echo "Warning: could not delete local branch $feature_branch (maybe not fully merged?)." >&2
fi

# Delete remote branch (ignore error if branch does not exist remotely)
if git push origin --delete "$feature_branch"; then
  echo "[git-feature-finish] Deleted remote branch $feature_branch."
else
  echo "Warning: could not delete remote branch $feature_branch (it may not exist)." >&2
fi

echo "[git-feature-finish] Done. Feature branch has been merged into develop and cleaned up."

