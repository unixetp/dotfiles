#!/usr/bin/env bash
set -euo pipefail

repo_dir="${DOTFILES_DIR:-$HOME/dotfiles}"

if [[ ! -d "$repo_dir/.git" ]]; then
    echo "Dotfiles repository not found: $repo_dir" >&2
    exit 1
fi

branch="$(git -C "$repo_dir" branch --show-current)"
if [[ "$branch" != "main" ]]; then
    echo "Skipping update because the current branch is '$branch', not 'main'." >&2
    exit 0
fi

if [[ -n "$(git -C "$repo_dir" status --porcelain)" ]]; then
    echo "Skipping update because the repository has local changes." >&2
    exit 0
fi

git -C "$repo_dir" fetch --quiet origin main
current="$(git -C "$repo_dir" rev-parse HEAD)"
latest="$(git -C "$repo_dir" rev-parse FETCH_HEAD)"

if [[ "$current" == "$latest" ]]; then
    exit 0
fi

if ! git -C "$repo_dir" merge-base --is-ancestor "$current" "$latest"; then
    echo "Skipping update because main cannot be fast-forwarded." >&2
    exit 1
fi

git -C "$repo_dir" merge --ff-only --quiet "$latest"
"$repo_dir/sync-configs.sh" "$repo_dir"
echo "Dotfiles updated to $latest"
