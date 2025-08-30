#!/usr/bin/env bash
set -euo pipefail

create_repo() {
  local dir="$1"
  mkdir -p "$dir"
  git -C "$dir" init -q
  printf "%s\n" "hello" > "$dir/file.txt"
  git -C "$dir" add file.txt
  git -C "$dir" -c user.email=a@b -c user.name=t commit -q -m init
  git -C "$dir" branch -q -M main
}

add_worktree_branch() {
  local repo="$1" worktree_path="$2" branch="$3" base_ref="$4"
  git -C "$repo" worktree add -q -b "$branch" "$worktree_path" "$base_ref"
}

add_worktree_detached() {
  local repo="$1" detach_path="$2" ref="$3"
  git -C "$repo" worktree add -q --detach "$detach_path" "$ref"
}
