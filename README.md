# git-worktrees

Simple shell helpers for Git worktrees:

- `wtnew` – create/open a worktree for a new **or existing** branch (fzf picker, Android Studio auto-open)
- `wtrm`  – safely remove a worktree (fzf preview, guards against uncommitted/unpushed work)
- `wtopen` – open an existing worktree for a branch (fzf picker, no mutations)
- `wtls` – list worktrees with status (clean/dirty, ahead/behind) and optional fzf/open

## Install

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/EtienneBBeaulac/git-worktrees/main/install.sh)"
```

Usage
```bash
wtnew
wtnew -n feature/x -b origin/main --no-open
wtopen feature/x   # open existing worktree for branch (or picker with no args)
wtls --fzf --open  # list worktrees and open selected in Android Studio
wtrm
wtrm -d ../repo-feature-x --delete-branch
```

Requirements
	•	git
	•	fzf (optional, recommended)

## wtnew options

- `-n, --name` Branch name (new or existing)
- `-b, --base` Base ref when creating a new branch (e.g. `origin/main`)
- `-d, --dir` Worktree directory
- `-r, --remote` Remote to track/push (default: infer from base or `origin`)
- `--app` App name to open (default: "Android Studio")
- `--no-open` Do not launch Android Studio
- `--push` Push new branch to selected remote and set upstream
- `--prefer-reuse` Prefer reusing an existing clean worktree slot over creating new
- `--inside-ok` Allow creating a path inside the current repo (unsafe)

Env:
- `WT_APP` default app (overrides "Android Studio")
- `WT_FZF_OPTS`, `WT_FZF_HEIGHT` customize fzf
- `WTNEW_ALWAYS_PUSH=1` always push new branches by default
- `WTNEW_PREFER_REUSE=1` prefer reusing clean slots by default
- `WT_DEBUG=1` print debug info

## wtopen options

- `wtopen [branchOrRef]` open existing worktree for branch; without an arg, show an interactive picker
- `--list` list worktrees (branch → dir) and exit
- `--fzf` force interactive picker even if a branch is provided
- `--no-open` don’t open, just print the path
- `--app NAME` app to open (default: "Android Studio")
- `--prune-stale` prune stale/prunable worktrees and exit
- `--dry-run` show the directory that would be opened
- `--exact` require exact branch match (skip short-name normalization)
- `--cwd` prefer matches from the current repo family when multiple

Env:
- `WT_APP`, `WT_FZF_OPTS`, `WT_FZF_HEIGHT`, `WT_DEBUG` (same semantics as above)

License

MIT ©  

---
