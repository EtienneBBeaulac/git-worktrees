#!/usr/bin/env zsh
# wt-discovery.zsh - Help system and feature discovery
# Part of Phase 1: Core Infrastructure

emulate -L zsh
setopt local_options pipefail
unsetopt xtrace verbose

# ============================================================================
# Help System
# ============================================================================

# Show contextual help based on current state
# Usage: wt_show_contextual_help <context> [details...]
wt_show_contextual_help() {
  local context="$1"; shift
  
  case "$context" in
    branch_selection)
      cat <<'EOF'
💡 Branch Selection Tips:
   • Type to filter branches fuzzy-find style
   • ↑↓ or Ctrl-J/K to navigate
   • Enter to select
   • Esc to cancel
   • Type a new name to create a new branch
EOF
      ;;
      
    worktree_creation)
      cat <<'EOF'
💡 Creating Worktree:
   • Branch name will be sanitized automatically
   • Use slashes for organization: feature/my-branch
   • Use --push to set upstream automatically
   • Use --start to set as default starting directory
EOF
      ;;
      
    worktree_removal)
      cat <<'EOF'
💡 Removing Worktree:
   • Safe by default: won't delete uncommitted work
   • Use --force to override safety checks
   • Branch is NOT deleted by default
   • Use --delete-branch to also remove the branch
EOF
      ;;
      
    fzf_shortcuts)
      cat <<'EOF'
⌨️  Keyboard Shortcuts (wt hub):
   • Enter:   Open worktree (or actions menu if toggled)
   • Ctrl-O:  Open worktree in editor
   • Ctrl-N:  Create new worktree
   • Ctrl-R:  Create new (prefer reuse existing slot)
   • Ctrl-D:  Remove selected worktree
   • Ctrl-P:  Prune stale worktree entries
   • Ctrl-A:  Actions menu (open, copy, remove, etc.)
   • Ctrl-E:  Toggle Enter behavior (open ↔ menu)
   • Ctrl-H:  Show help
   • Esc:     Cancel/exit
EOF
      ;;
      
    error_recovery)
      cat <<'EOF'
💡 Error Recovery:
   • Don't panic! You have options:
   • Most errors offer retry with corrections
   • Session state is saved for recovery
   • Failed operations can be rolled back
   • Use ESC or Ctrl-C to cancel safely
EOF
      ;;
      
    *)
      echo "No contextual help available for: $context"
      return 1
      ;;
  esac
}

# Show command examples
# Usage: wt_show_examples <command>
wt_show_examples() {
  local cmd="$1"
  
  case "$cmd" in
    wt)
      cat <<'EOF'
📖 wt Examples:

  # Interactive fuzzy selection
  $ wt
  
  # Quick open by name
  $ wt feature/my-branch
  
  # Create new worktree (subcommand)
  $ wt new feature/test
  
  # List all worktrees
  $ wt list
  
  # Remove worktree
  $ wt remove feature/old
  
  # Open in specific editor
  $ WT_EDITOR=code wt feature/ui
  
  # Start in branch-first mode
  $ wt --start new
EOF
      ;;
      
    wtnew)
      cat <<'EOF'
📖 wtnew Examples:

  # Create from current branch
  $ wtnew feature/new-feature
  
  # Create from specific base
  $ wtnew feature/new -b main
  
  # Create and set upstream
  $ wtnew feature/new --push
  
  # Prefer reusing existing worktree slot
  $ wtnew feature/existing --prefer-reuse
  
  # Custom worktree directory
  $ wtnew feature/new -d /custom/path
  
  # Using flags explicitly
  $ wtnew -n feature/new -b origin/main --push
EOF
      ;;
      
    wtrm)
      cat <<'EOF'
📖 wtrm Examples:

  # Interactive removal
  $ wtrm
  
  # Remove specific worktree
  $ wtrm feature/old
  
  # Remove and delete branch
  $ wtrm feature/old --delete-branch
  
  # Force removal (skip safety checks)
  $ wtrm feature/broken --force
  
  # Dry run to see what would be removed
  $ wtrm --dry-run
  
  # Remove multiple worktrees
  $ wtrm feature/a feature/b feature/c
EOF
      ;;
      
    wtopen)
      cat <<'EOF'
📖 wtopen Examples:

  # Open in default editor
  $ wtopen feature/my-branch
  
  # Open in specific editor
  $ EDITOR=code wtopen feature/ui
  
  # Open at exact path
  $ wtopen /path/to/worktree
  
  # Open with custom cd (bash)
  $ . wtopen feature/test
  
  # Prune stale worktrees first
  $ wtopen --prune feature/branch
EOF
      ;;
      
    wtls)
      cat <<'EOF'
📖 wtls Examples:

  # List all worktrees
  $ wtls
  
  # Interactive FZF selection
  $ wtls --fzf
  
  # Show ahead/behind status
  $ wtls --status
  
  # Compact format
  $ wtls --compact
  
  # JSON output
  $ wtls --json
  
  # Filter by pattern
  $ wtls | grep feature/
EOF
      ;;
      
    *)
      echo "No examples available for: $cmd"
      return 1
      ;;
  esac
}

# ============================================================================
# Hint Engine
# ============================================================================

# Show hints based on context
# Usage: wt_show_hints <situation> [details...]
wt_show_hints() {
  local situation="$1"; shift
  
  case "$situation" in
    first_time)
      cat <<'EOF'
👋 Welcome to git-worktrees!

Quick Start:
  1. Run 'wt' for interactive worktree hub
  2. Press Ctrl-H in hub to see keyboard shortcuts
  3. Use 'wt new' or 'wtnew' to create new worktrees
  4. Use 'wt remove' or 'wtrm' to remove worktrees

💡 Tip: Run 'wt --tutorial' for a guided introduction
EOF
      ;;
      
    no_worktrees)
      cat <<'EOF'
📝 No worktrees found besides main.

Create your first worktree:
  $ wtnew feature/my-first-branch

Or create from specific base:
  $ wtnew feature/my-branch -b develop
EOF
      ;;
      
    many_worktrees)
      local count="$1"
      cat <<EOF
📊 You have $count worktrees!

Performance tips:
  • Use 'wt <pattern>' for quick filtering
  • Set WT_IGNORE_PATTERNS to hide certain branches
  • Consider cleaning up old worktrees with 'wtrm'
  • Use 'wtls --status' to find stale branches
EOF
      ;;
      
    outdated_branch)
      local branch="$1"
      local behind="$2"
      cat <<EOF
⚠️  Branch '$branch' is $behind commits behind!

Update options:
  1. git pull (if safe)
  2. git fetch && git rebase
  3. Create fresh worktree from updated base
  
Try: wt $branch && git pull
EOF
      ;;
      
    untracked_changes)
      local path="$1"
      cat <<EOF
⚠️  Worktree has uncommitted changes: $path

Options:
  1. Commit changes: git commit -am "msg"
  2. Stash changes: git stash
  3. Create new worktree: wtnew feature/clean
  
💡 wtrm will refuse to delete this worktree (safety)
EOF
      ;;
      
    *)
      return 0  # No hints for this situation
      ;;
  esac
}

# ============================================================================
# Cheatsheet Generator
# ============================================================================

# Generate cheatsheet
# Usage: wt_cheatsheet [category]
wt_cheatsheet() {
  local category="${1:-all}"
  
  if [[ "$category" == "all" ]] || [[ "$category" == "commands" ]]; then
    cat <<'EOF'
╔══════════════════════════════════════════════════════════════╗
║                 git-worktrees CHEATSHEET                      ║
╚══════════════════════════════════════════════════════════════╝

CORE COMMANDS:
  wt [pattern]           Interactive worktree selection
  wtnew <branch>         Create new worktree
  wtrm [worktree]        Remove worktree(s)
  wtopen <worktree>      Open worktree in editor
  wtls                   List all worktrees

COMMON WORKFLOWS:
  # Start new feature
  $ wtnew feature/my-feature --push
  
  # Quick switch
  $ wt feature
  
  # Clean up old feature
  $ wtrm feature/old --delete-branch
  
  # Review changes
  $ wt feature && git diff main

EOF
  fi
  
  if [[ "$category" == "all" ]] || [[ "$category" == "shortcuts" ]]; then
    cat <<'EOF'
KEYBOARD SHORTCUTS (wt hub):
  Enter       Open worktree (or menu if toggled)
  Ctrl-O      Open in editor
  Ctrl-N      Create new worktree
  Ctrl-R      Create new (reuse slot)
  Ctrl-D      Remove worktree
  Ctrl-P      Prune stale entries
  Ctrl-A      Actions menu
  Ctrl-E      Toggle Enter mode
  Ctrl-H      Show help
  Esc         Cancel

EOF
  fi
  
  if [[ "$category" == "all" ]] || [[ "$category" == "options" ]]; then
    cat <<'EOF'
COMMON OPTIONS:
  --help, -h             Show help
  -b, --base <branch>    Base branch for new worktree
  --push                 Set and push upstream
  --force                Skip safety checks
  --delete-branch        Also delete the branch
  --dry-run              Show what would happen
  --prefer-reuse         Reuse existing clean worktree slot

EOF
  fi
  
  if [[ "$category" == "all" ]] || [[ "$category" == "env" ]]; then
    cat <<'EOF'
ENVIRONMENT VARIABLES:
  WT_EDITOR              Editor to use (overrides EDITOR)
  WT_APP                 Alias for WT_EDITOR
  WT_FZF_OPTS            Custom fzf options
  WT_FZF_HEIGHT          FZF height (default: 40%)
  WT_DEBUG               Enable debug output
  WT_NO_RECOVERY         Disable error recovery
  WT_TERMINAL_APP        Terminal for "Open in terminal"
  WTNEW_ALWAYS_PUSH      Always push new branches
  WTNEW_PREFER_REUSE     Prefer reusing worktree slots

EOF
  fi
  
  if [[ "$category" == "all" ]] || [[ "$category" == "tips" ]]; then
    cat <<'EOF'
PRO TIPS:
  • Prefix branch names with category: feature/, fix/, docs/
  • Use --prefer-reuse to avoid duplicate worktrees
  • Run 'wt list' or 'wtls' to see all worktrees
  • Use Ctrl-A in hub for quick actions menu
  • Use Ctrl-E to toggle Enter between open/menu mode
  • Configure editor once: wt config set editor "Cursor"

LEARN MORE:
  $ wt --help
  $ wt --tutorial
  $ wtnew --help
  $ man git-worktree

EOF
  fi
  
  if [[ "$category" != "all" ]] && [[ "$category" != "commands" ]] && \
     [[ "$category" != "shortcuts" ]] && [[ "$category" != "options" ]] && \
     [[ "$category" != "env" ]] && [[ "$category" != "tips" ]]; then
    echo "Unknown cheatsheet category: $category"
    echo "Available: commands, shortcuts, options, env, tips, all"
    return 1
  fi
}

# ============================================================================
# Feature Discovery
# ============================================================================

# Discover available features
# Usage: wt_discover_features
wt_discover_features() {
  cat <<'EOF'
🔍 Discovering git-worktrees features...

INTERACTIVE FEATURES:
  ✓ Fuzzy finding with fzf
  ✓ Real-time git status in preview
  ✓ Keyboard shortcuts (Ctrl-A, Ctrl-N, etc.)
  ✓ Contextual help (Ctrl-H)
  ✓ Actions menu for quick operations

SMART FEATURES:
  ✓ Branch name sanitization
  ✓ Error recovery with suggestions
  ✓ Session state persistence
  ✓ Transaction rollback
  ✓ Fuzzy branch matching
  ✓ Ahead/behind tracking

WORKFLOW FEATURES:
  ✓ Auto-cd to worktrees
  ✓ Prefer-reuse existing worktrees
  ✓ Safe removal (checks for uncommitted work)
  ✓ Batch operations
  ✓ Dry-run mode

CUSTOMIZATION:
  ✓ Environment variables (WT_*)
  ✓ Custom FZF options
  ✓ Editor integration
  ✓ Start directory management

Run 'wt_cheatsheet' to see all commands and shortcuts!
EOF
}

# Check if feature is available
# Usage: wt_has_feature <feature_name>
wt_has_feature() {
  local feature="$1"
  
  case "$feature" in
    fzf)
      command -v fzf >/dev/null 2>&1
      ;;
    recovery)
      [[ -z "${WT_NO_RECOVERY:-}" ]]
      ;;
    clipboard)
      command -v pbcopy >/dev/null 2>&1 || \
      command -v xclip >/dev/null 2>&1 || \
      command -v wl-copy >/dev/null 2>&1
      ;;
    session_state)
      [[ -d "${HOME}/.cache/git-worktrees/sessions" ]] || \
      mkdir -p "${HOME}/.cache/git-worktrees/sessions" 2>/dev/null
      ;;
    *)
      return 1
      ;;
  esac
}

# Show feature status
# Usage: wt_feature_status
wt_feature_status() {
  echo "Feature Status:"
  echo ""
  
  local features=(
    "fzf:Fuzzy finding"
    "recovery:Error recovery"
    "clipboard:Clipboard support"
    "session_state:Session persistence"
  )
  
  for feature_pair in "${features[@]}"; do
    local feature="${feature_pair%%:*}"
    local name="${feature_pair#*:}"
    
    if wt_has_feature "$feature"; then
      echo "  ✅ $name"
    else
      echo "  ❌ $name (not available)"
    fi
  done
}

# ============================================================================
# Interactive Help
# ============================================================================

# Show interactive help menu
# Usage: wt_help_interactive
wt_help_interactive() {
  local choice
  
  while true; do
    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║              git-worktrees Help Menu                      ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    echo "  [1] Quick Start Guide"
    echo "  [2] Command Examples"
    echo "  [3] Keyboard Shortcuts"
    echo "  [4] Cheatsheet"
    echo "  [5] Feature Discovery"
    echo "  [6] Troubleshooting"
    echo "  [q] Quit"
    echo ""
    printf "Select option: "
    
    read -r choice
    
    case "$choice" in
      1)
        wt_show_hints first_time
        ;;
      2)
        echo "Which command? (wt/wtnew/wtrm/wtopen/wtls): "
        read -r cmd
        wt_show_examples "$cmd"
        ;;
      3)
        wt_show_contextual_help fzf_shortcuts
        ;;
      4)
        wt_cheatsheet
        ;;
      5)
        wt_discover_features
        echo ""
        wt_feature_status
        ;;
      6)
        wt_show_contextual_help error_recovery
        ;;
      q|Q)
        break
        ;;
      *)
        echo "Invalid choice. Try again."
        ;;
    esac
    
    echo ""
    printf "Press Enter to continue..."
    read -r
  done
}

# ============================================================================
# Export Functions (silently)
# ============================================================================

{
  typeset -gf wt_show_contextual_help wt_show_examples wt_show_hints
  typeset -gf wt_cheatsheet wt_discover_features
  typeset -gf wt_has_feature wt_feature_status
  typeset -gf wt_help_interactive
} >/dev/null 2>&1

