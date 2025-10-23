# git-worktrees

> Simple, powerful Git worktree management with fuzzy finding

## Why Git Worktrees?

Work on multiple branches simultaneously without the pain of `git stash` and constant branch switching.

**Before worktrees:**
```bash
# Working on a feature
$ git checkout feature-branch
# ... coding ...

# Need to quickly check main
$ git stash                    # 😰 Save your work
$ git checkout main            # Switch branch
# ... check something ...
$ git checkout feature-branch  # Switch back
$ git stash pop                # 🤞 Hope nothing breaks
```

**With worktrees:**
```bash
# Each branch is its own directory
$ cd ~/code/repo-feature/      # Work on feature
$ cd ~/code/repo-main/         # Check main
$ cd ~/code/repo-feature/      # Back to work
# Everything stays intact! ✨
```

**Perfect for:**
- 🎯 Working on multiple features simultaneously
- 👀 Reviewing PRs without losing your current work
- 🧪 Running tests on one branch while developing another
- 🔍 Comparing branches side-by-side in different editor windows

## Commands

- `wt`     – Interactive hub to list, open, create, and manage worktrees (fuzzy find with fzf)
- `wtnew`  – Create/open a worktree for a new or existing branch (smart detection)
- `wtrm`   – Safely remove a worktree (guards against uncommitted/unpushed work)
- `wtopen` – Open an existing worktree for a branch (fuzzy picker, no mutations)
- `wtls`   – List worktrees with status (clean/dirty, ahead/behind)

## Install

### Via Install Script

```bash
curl -fsSL https://raw.githubusercontent.com/EtienneBBeaulac/git-worktrees/main/install.sh | bash
```

After install, restart your shell or run:

```bash
source ~/.zshrc
```

For local/offline testing, you can override downloads with a local repo path:

```bash
REPO_RAW="file://$PWD" bash install.sh
```

### Via Homebrew (Recommended)

```bash
brew tap etiennebbeaulac/tap
brew install git-worktrees
```

**That's it!** Commands are automatically available in your PATH. No configuration needed. ✨

```bash
wt --help  # Try it now!
```

**Updating:**
```bash
brew upgrade git-worktrees
```

## Quick Start

```bash
# Create your first worktree
wtnew feature-branch

# List and switch between worktrees (interactive)
wt

# Open specific worktree
wtopen feature-branch

# Remove a worktree safely
wtrm
```

## Usage Examples

```bash
wt                          # Interactive hub (fuzzy find with fzf)
wt feature-x                # Quick open/create for branch
wtnew feature-x             # Create worktree for new or existing branch
wtnew -n feature/x -b origin/main --no-open  # Advanced creation
wtopen feature/x            # Open existing worktree
wtls                        # List all worktrees with status
wtls --fzf --open           # List and open selected in your editor
wtrm                        # Interactive removal (includes "Remove all detached")
wtrm -d ../repo-feature-x --delete-branch    # Remove and delete branch
wtrm --rm-detached --yes    # Bulk remove all detached worktrees
```

## Requirements

- git
- fzf (optional, recommended; without it, non-interactive fallbacks are used)

## wtnew options

- `-n, --name` Branch name (new or existing)
- `-b, --base` Base ref when creating a new branch (e.g. `origin/main`)
- `-d, --dir` Worktree directory
- `-r, --remote` Remote to track/push (default: infer from base or `origin`)
- `--app` App name to open (default: auto-detected from your system)
- `--no-open` Do not open in editor/IDE
- `--push` Push new branch to selected remote and set upstream
- `--prefer-reuse` Prefer reusing an existing clean worktree slot over creating new
- `--inside-ok` Allow creating a path inside the current repo (unsafe)

Env:
- `WT_APP` or `WT_EDITOR` Override auto-detected editor (e.g. "VS Code", "IntelliJ IDEA")
- `EDITOR` / `VISUAL` Standard editor environment variables (respected)
- `WT_FZF_OPTS`, `WT_FZF_HEIGHT` Customize fzf appearance
- `WTNEW_ALWAYS_PUSH=1` Always push new branches by default
- `WTNEW_PREFER_REUSE=1` Prefer reusing clean slots by default
- `WT_DEBUG=1` Print debug info

## wtopen options

- `wtopen [branchOrRef]` Open existing worktree for branch; without an arg, show an interactive picker
- `--list` List worktrees (branch → dir) and exit
- `--fzf` Force interactive picker even if a branch is provided
- `--no-open` Don't open in editor, just print the path
- `--app NAME` App to open (default: auto-detected)
- `--prune-stale` Prune stale/prunable worktrees and exit
- `--dry-run` Show the directory that would be opened
- `--exact` Require exact branch match (skip short-name normalization)
- `--cwd` Prefer matches from the current repo family when multiple

Env:
- `WT_APP` / `WT_EDITOR` / `EDITOR` / `VISUAL` (see wtnew options above)
- `WT_FZF_OPTS`, `WT_FZF_HEIGHT`, `WT_DEBUG` (same as wtnew)

## wt (hub) keys and options

- Start: list of worktrees with "➕ New branch…" and optional "🧵 Show detached…"
- Keys:
  - Enter: open (or actions when toggled); Ctrl-E toggles Enter between open/menu (persisted)
  - Ctrl-N: create (chooser: smart reuse / force reuse / new dir)
  - Ctrl-D: remove; Ctrl-P: prune stale; Ctrl-A: actions; Ctrl-O: open; Ctrl-H: help
- Actions menu (Ctrl-A): Includes "Remove all detached" option for bulk removal
- Flags: `--start list|new`, `--detached`, `--enter-default open|menu`
- Env: `WTHUB_ENTER_DEFAULT=open|menu`, `WT_TERMINAL_APP` for "Open in terminal"

## Testing

Run the non-interactive test suite:

```bash
make test           # full suite
make test-fast      # quick smoke (FAST_ONLY subset)
```

## Uninstall

**Install script:**
```bash
curl -fsSL https://raw.githubusercontent.com/EtienneBBeaulac/git-worktrees/main/uninstall.sh | bash
```

**Homebrew:**
```bash
brew uninstall git-worktrees
brew untap etiennebbeaulac/tap  # Optional
```

License

MIT ©  

---
