#!/usr/bin/env bash
set -euo pipefail

create_bare_remote() {
  local dir="$1"
  mkdir -p "$dir"
  git -C "$dir" init --bare -q
}

add_remote() {
  local repo="$1" name="$2" bare_dir="$3"
  git -C "$repo" remote add "$name" "$bare_dir"
}

initial_push_main() {
  local repo="$1" remote="$2"
  git -C "$repo" push -u "$remote" main >/dev/null 2>&1 || true
}

clone_bare() {
  local bare_dir="$1" clone_dir="$2"
  git clone -q "$bare_dir" "$clone_dir"
}

commit_change() {
  local repo_dir="$1" file_rel="${2:-file.txt}" msg="${3:-test}"
  printf "%s\n" "${RANDOM}" >> "$repo_dir/$file_rel"
  git -C "$repo_dir" add "$file_rel"
  git -C "$repo_dir" -c user.email=a@b -c user.name=t commit -q -m "$msg"
}

push_branch() {
  local repo_dir="$1" branch="$2"
  git -C "$repo_dir" push -u origin "$branch" >/dev/null 2>&1 || true
}
