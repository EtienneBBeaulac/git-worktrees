# git-worktrees v1.1.0 - The Professional Release 🚀

We're excited to announce v1.1.0, a major UX overhaul that makes git-worktrees more discoverable, beginner-friendly, and professional!

## 🎯 What's New

### Improved UX: See What's Happening 👀

**Problem:** FZF selections disappeared after choosing, leaving no record of what happened.

**Fixed:** All selections now echo to terminal:
```bash
✓ Selected: feature/my-branch           # Shows your choice
✓ Base: origin/main                     # Shows base ref (if picked)
✓ Opening worktree: repo-feature        # Shows context
```

**Complete visibility** - Every step is now recorded in terminal history!

---

### Editor Confirmation & Control 🎨

**New:** Interactive confirmation before opening editor:
```bash
📂 Open in Cursor? [Y/n/other/save]:
```

**Options:**
- **Y** - Open in detected editor
- **n** - Don't open, just show path
- **other** - Choose from menu of 9 editors
- **save** - Save as default (updates config)

**Critical fix:** Correct editor now opens every time (was opening Android Studio regardless of choice)

**Skip prompt:** `export WTNEW_SKIP_EDITOR_CONFIRM=1`

---

### Git-Style Subcommands (Industry Standard)

Work with worktrees using familiar command patterns:

```bash
wt new feature           # Create worktree (like git checkout -b)
wt remove                # Remove worktree (like git branch -d)
wt open feature          # Open existing worktree
wt list                  # List all worktrees
wt config edit           # Manage configuration
```

**Bonus:** All your old commands still work! `wtnew`, `wtrm`, `wtopen`, `wtls` are now "quick access" shortcuts.

---

### Welcome Beginners! 👋

**First-time users get helpful guidance:**
- Clear explanation of what worktrees are
- Concrete examples showing the benefits
- Links to interactive tutorial

**Interactive tutorial:** Run `wt --tutorial` for a 4-part walkthrough covering:
1. What are worktrees and why use them?
2. How to create and manage worktrees
3. Keyboard shortcuts and power features
4. Quick start workflow and pro tips

---

### Better Error Messages 💡

No more cryptic errors! Every error now includes:
- Clear explanation of what went wrong
- Concrete suggestions for fixing it
- Examples of commands to try

**Before:**
```
❌ Not a git repo
```

**Now:**
```
❌ Not a git repository

This command must be run from inside a git repository.

Try:
  cd /path/to/your/repo        # Navigate to your repository
  git init                     # Initialize new repository
  git clone <url>              # Clone existing repository

What's a git repository?
  A directory containing a .git folder that tracks your code history.
```

---

### Configuration Management ⚙️

New `wt config` command for easy customization:

```bash
wt config edit           # Open config in editor
wt config show           # View current settings
wt config init           # Create config with defaults
```

**Config file:** `~/.config/git-worktrees/config`
- Auto-created with smart defaults
- Customize editor, behavior, UI
- Priority: flags > env vars > config file

**What's configurable:**
- Editor/IDE selection (auto-detected)
- Auto-open behavior after creating worktree
- Auto-push new branches to remote
- FZF height and appearance
- And more!

---

## 🔧 Improvements

### Documentation Overhaul
- Clearer structure: Hub → Subcommands → Shortcuts
- Homebrew installation moved to top (it's easier!)
- Modern examples using subcommand style
- "Why Git Worktrees?" section for newcomers

### User Experience Polish
- Consistent error messaging across all commands
- Version flag (`--version`) on all commands
- Smart editor detection (no more "Android Studio" assumptions!)
- Help text updated everywhere

---

## ✅ Backward Compatible

**Nothing breaks!** All v1.0.x workflows still work:
- `wtnew`, `wtrm`, `wtopen`, `wtls` - all still available
- Same flags and options
- Zero migration needed

We just added new ways to do things. Use what you prefer!

---

## 📊 By the Numbers

- **25 new tests** ensuring quality
- **6 major features** added
- **100% backward compatible**
- **Zero breaking changes**

---

## 🚀 Get Started

**New users:**
```bash
brew install git-worktrees
wt --tutorial            # Start with the tutorial
wt                       # Open the interactive hub
```

**Existing users:**
```bash
brew upgrade git-worktrees
wt help                  # Check out what's new
```

---

## 📝 Full Changelog

See [CHANGELOG.md](CHANGELOG.md) for complete details.

## 🙏 Thank You

Thanks for using git-worktrees! Questions or feedback? [Open an issue](https://github.com/EtienneBBeaulac/git-worktrees/issues)!

