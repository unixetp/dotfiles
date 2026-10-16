#!/usr/bin/env bash
set -euo pipefail

repo_dir="${DOTFILES_DIR:-$HOME/dotfiles}"
notify_current=false

case "${1:-}" in
    "") ;;
    --notify-current) notify_current=true ;;
    *) echo "Usage: $0 [--notify-current]" >&2; exit 2 ;;
esac

notify_user() {
    command -v notify-send >/dev/null 2>&1 || return 0
    notify-send --app-name=Dotfiles --urgency=normal "Dotfiles" "$1" >/dev/null 2>&1 || true
}

notify_startup_issue() {
    if [[ "$notify_current" == true ]]; then
        notify_user "$1"
    fi
}

lock_dir="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}"
exec 9>"$lock_dir/dotfiles-update.lock"
if ! flock -n 9; then
    notify_startup_issue "Another dotfiles update check is already running."
    exit 0
fi

if [[ ! -d "$repo_dir/.git" ]]; then
    echo "Dotfiles repository not found: $repo_dir" >&2
    notify_startup_issue "Repository not found at $repo_dir"
    exit 1
fi

branch="$(git -C "$repo_dir" branch --show-current)"
if [[ "$branch" != "main" ]]; then
    echo "Skipping update because the current branch is '$branch', not 'main'." >&2
    notify_startup_issue "Update skipped: current branch is '$branch', not main."
    exit 0
fi

if [[ -n "$(git -C "$repo_dir" status --porcelain)" ]]; then
    echo "Skipping update because the repository has local changes." >&2
    notify_startup_issue "Update skipped because ~/dotfiles has local changes."
    exit 0
fi

if [[ "$notify_current" == true ]]; then
    sleep 3
fi

if ! timeout 30s git -C "$repo_dir" fetch --quiet origin main; then
    echo "Could not check GitHub for dotfiles updates." >&2
    notify_startup_issue "Could not check GitHub for updates."
    exit 1
fi

current="$(git -C "$repo_dir" rev-parse HEAD)"
latest="$(git -C "$repo_dir" rev-parse FETCH_HEAD)"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
applied=""
if [[ -f "$state_dir/applied-commit" ]]; then
    applied="$(<"$state_dir/applied-commit")"
fi

if [[ "$current" == "$latest" && "$applied" == "$current" ]]; then
    if [[ "$notify_current" == true ]]; then
        notify_user "No updates available. Running ${current:0:7}."
    fi
    exit 0
fi

if [[ "$current" != "$latest" ]]; then
    if ! git -C "$repo_dir" merge-base --is-ancestor "$current" "$latest"; then
        echo "Skipping update because main cannot be fast-forwarded." >&2
        notify_startup_issue "Update skipped: local main cannot be fast-forwarded."
        exit 1
    fi
    git -C "$repo_dir" merge --ff-only --quiet "$latest"
fi

if ! "$repo_dir/sync-configs.sh" "$repo_dir"; then
    echo "Could not apply the current dotfiles." >&2
    notify_startup_issue "Downloaded updates but could not apply the configs."
    exit 1
fi

if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    hyprctl reload >/dev/null 2>&1 || true
    pkill -SIGUSR2 -x waybar >/dev/null 2>&1 || true
fi

echo "Dotfiles applied at $latest"
notify_user "Updated to ${latest:0:7} and applied."
