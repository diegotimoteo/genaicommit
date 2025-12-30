#!/usr/bin/env bash
# Synchronize the current feature/* branch with the latest origin/develop.
# - Validates that we are on a feature/* branch
# - Ensures the working tree is clean
# - Updates local develop from origin
# - Merges origin/develop into the current feature branch with --no-ff
# - Pushes the updated feature branch to origin

set -euo pipefail

# Determine current branch name
current_branch=$(git rev-parse --abbrev-ref HEAD)

# Ensure we are on a feature/* branch
if [[ "$current_branch" != feature/* ]]; then
  echo "Error: git-feature-sync must be run from a feature/* branch (current: $current_branch)" >&2
  exit 1
fi

# Ensure working tree is clean (no unstaged or staged changes)
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Error: working tree not clean. Commit, stash, or discard changes before syncing." >&2
  exit 1
fi

echo "[git-feature-sync] Fetching latest changes from origin..."
git fetch origin

echo "[git-feature-sync] Updating local develop from origin/develop..."
git checkout develop
git pull origin develop

echo "[git-feature-sync] Switching back to feature branch $current_branch..."
git checkout "$current_branch"

echo "[git-feature-sync] Merging origin/develop into $current_branch with --no-ff..."
git merge --no-ff origin/develop

# Optional: you may want to run tests here; keep commented to avoid automatic test runs by default.
# echo "[git-feature-sync] Running tests..."
# astro dev pytest tests/ || { echo "[git-feature-sync] Tests failed. Aborting push." >&2; exit 1; }

echo "[git-feature-sync] Pushing updated feature branch to origin..."
git push

echo "[git-feature-sync] Done. Feature branch is synchronized with origin/develop."

