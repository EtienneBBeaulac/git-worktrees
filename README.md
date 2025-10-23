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

**Interactive hub:**
- `wt` – Interactive fuzzy finder to list, switch, create, and manage worktrees

**Subcommands:**
- `wt new` / `wt n` – Create/open a worktree for a new or existing branch
- `wt remove` / `wt rm` – Safely remove a worktree (guards against uncommitted/unpushed work)
- `wt open` / `wt o` – Open an existing worktree for a branch
- `wt list` / `wt ls` – List worktrees with status (clean/dirty, ahead/behind)
- `wt prune` – Remove stale worktree references
- `wt config` – Manage configuration (edit, show, init)
- `wt help` – Show detailed help

**Quick access (shorthand):**
- `wtnew`, `wtrm`, `wtopen`, `wtls` – Direct commands (same as subcommands, just faster to type)

## Install

### Via Homebrew (Recommended)

```bash
brew tap etiennebbeaulac/tap
brew install git-worktrees
```

**That's it!** Commands are immediately available. ✨

**First Run:**
On your first use, git-worktrees will ask you to choose your default editor (VS Code, Cursor, IntelliJ IDEA, etc.). This one-time setup takes 5 seconds and you're good to go!

```bash
wt --help  # Try it now!
```

**Updating:**
```bash
brew upgrade git-worktrees
```

### Via Install Script

```bash
curl -fsSL https://raw.githubusercontent.com/EtienneBBeaulac/git-worktrees/main/install.sh | bash
```

Then restart your shell or run: `source ~/.zshrc`

For local/offline testing, you can override downloads with a local repo path:

```bash
REPO_RAW="file://$PWD" bash install.sh
```

## Quick Start

```bash
# Interactive hub - the main way to use git-worktrees
wt                       # Fuzzy-find worktrees, switch, create, manage

# Or use direct commands when you know what you want
wt new feature-branch    # Create your first worktree
wt open feature-branch   # Open specific worktree
wt remove                # Remove a worktree safely
wt list                  # List all worktrees with status

# Shorthand versions (same thing, less typing)
wtnew feature-branch     # Same as: wt new feature-branch
wtopen feature-branch    # Same as: wt open feature-branch
```

## Usage Examples

```bash
# Interactive hub - main interface
wt                           # Fuzzy-find and switch between worktrees
wt feature-x                 # Quick open/create for specific branch

# Subcommands - when you know what you want
wt new feature-x             # Create worktree for new or existing branch
wt new feature/x -b main     # Create from 'main' branch
wt open feature/x            # Open existing worktree
wt list                      # List all worktrees with status
wt list --fzf --open         # List and open selected in your editor
wt remove                    # Interactive removal (includes "Remove all detached")
wt remove -d ../repo-feature-x --delete-branch  # Remove and delete branch
wt prune                     # Remove stale worktree references
wt config edit               # Edit configuration file
wt config set editor "Cursor"  # Change your default editor
wt config get editor         # Show current editor

# Shorthand - same commands, less typing
wtnew feature-x              # Same as: wt new feature-x
wtrm                         # Same as: wt remove
wtrm --rm-detached --yes     # Bulk remove all detached worktrees
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

Environment variables:
- `WT_EDITOR` or `WT_APP` – Override auto-detected editor (e.g. "VS Code", "IntelliJ IDEA")
- `EDITOR` / `VISUAL` – Standard editor environment variables (respected)
- `WT_FZF_OPTS`, `WT_FZF_HEIGHT` – Customize fzf appearance
- `WTNEW_ALWAYS_PUSH=1` – Always push new branches by default
- `WTNEW_PREFER_REUSE=1` – Prefer reusing clean slots by default
- `WTNEW_AUTO_OPEN=0` – Disable auto-opening editor
- `WT_DEBUG=1` – Print debug info

Configuration file (`~/.config/git-worktrees/config`):
- Auto-created on first run with your chosen editor
- Manage with: `wt config edit`, `wt config set <key> <value>`, or `wt config get <key>`
- Change editor anytime: `wt config set editor "Cursor"` or use Ctrl-A → "Change editor" in hub
- Priority: flags > env vars > config file

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

**Subcommands:**
- `wt new <branch>` – Create/open worktree
- `wt remove` – Remove worktree
- `wt open <branch>` – Open existing worktree
- `wt list` – List all worktrees
- `wt config` – Manage configuration (edit, show, init)
- `wt --tutorial` – Interactive tutorial for beginners
- `wt help` – Full documentation

**Interactive hub:**
- Start: list of worktrees with "➕ New branch…" and optional "🧵 Show detached…"
- Keys:
  - Enter: open (or actions when toggled); Ctrl-E toggles Enter between open/menu (persisted)
  - Ctrl-N: create (chooser: smart reuse / force reuse / new dir)
  - Ctrl-D: remove; Ctrl-P: prune stale; Ctrl-A: actions; Ctrl-O: open; Ctrl-H: help
- Actions menu (Ctrl-A): Includes "Change editor", "Remove all detached", and more
- Flags: `--start list|new`, `--detached`, `--enter-default open|menu`
- Env: `WTHUB_ENTER_DEFAULT=open|menu`, `WT_TERMINAL_APP` for "Open in terminal"

**Configuration:**
- Config file: `~/.config/git-worktrees/config`
- Auto-created on first run with smart defaults
- Edit with: `wt config edit` or manually
- Priority: flags > env vars > config file

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
