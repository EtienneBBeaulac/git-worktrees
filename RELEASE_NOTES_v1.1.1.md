# Release Notes - v1.1.1

## 🎯 Major UX Overhaul: Clean, Simple, No More Confusion

This release completely reimagines the editor setup experience, eliminating the confusing prompt and replacing it with a clean, one-time setup flow.

---

## 🎉 What's New

### First-Run Setup (Once and Done!)

**Problem:** Users were confused by prompts every time they created a worktree.

**Solution:** One-time welcome menu on first use:

```
👋 Welcome to git-worktrees!

📂 Choose your default editor:
  1) Android Studio
  2) Visual Studio Code
  3) Cursor
  4) IntelliJ IDEA
  5) PyCharm
  6) WebStorm
  7) Sublime Text
  8) vim
  9) Don't auto-open (show path only)

Choice [1-9]:
```

- **Runs once** - Never bothered again
- **Takes 5 seconds** - Quick and painless
- **Saves automatically** - Your choice is remembered

---

### Silent Auto-Open (No More Prompts!)

**Before v1.1.1:**
```bash
$ wt new feature
...
📂 Open in Cursor? [Y/n/other/save]:  ← Annoying prompt every time!
```

**After v1.1.1:**
```bash
$ wt new feature
...
🚀 Opening in Cursor…  ← Just works!
```

**Clean, fast, and automatic!** ✨

---

### Change Editor Anytime

Three easy ways to change your editor:

**1. From the hub (Ctrl-A):**
```bash
$ wt
→ Ctrl-A → "Change editor" → Select from menu → Done!
```

**2. From CLI:**
```bash
$ wt config set editor "IntelliJ IDEA"
✅ Updated: editor=IntelliJ IDEA
```

**3. Edit config:**
```bash
$ wt config edit  # Opens ~/.config/git-worktrees/config
```

---

### Enhanced Config Management

New commands for config management:

```bash
# Set values
wt config set editor "Cursor"
wt config set behavior.autoopen true

# Get values
wt config get editor
# → Cursor

# Show all config
wt config show
```

---

## 🔧 Technical Details

### Config File: `~/.config/git-worktrees/config`

Auto-created on first run with your chosen editor:

```ini
# git-worktrees configuration
editor=Cursor
behavior.autoopen=true
behavior.editor_prompt=silent
```

### Priority System

1. **Command flags** (highest priority)
2. **Environment variables** (`WT_EDITOR`, `WT_APP`)
3. **Config file** (lowest priority, persistent defaults)

---

## 📚 Migration Guide

### For Existing Users

**Nothing to change!** Your existing config is preserved.

If you had set `editor=` in your config, it will continue to work as before. The new first-run setup only appears if no config exists.

### For New Users

Just run any `wt` command and follow the one-time setup!

---

## 🎨 What This Means for You

### ✅ First-Time Users
- Clear, welcoming onboarding
- Choose your editor once
- Start working immediately

### ✅ Regular Users
- No more annoying prompts
- Everything just works
- Change editor whenever you want

### ✅ Power Users
- Full control via CLI (`wt config set`)
- Config file for advanced customization
- Environment variables still work

---

## 🐛 Bug Fixes

- Fixed editor detection fallbacks
- Improved config file initialization
- Better error handling for missing editors

---

## 📦 Upgrade Now!

### Homebrew:
```bash
brew upgrade git-worktrees
```

### Install Script:
```bash
curl -fsSL https://raw.githubusercontent.com/EtienneBBeaulac/git-worktrees/main/install.sh | bash
source ~/.zshrc
```

---

## 💬 Feedback

Try the new flow and let us know what you think!

**Issues/Feedback:** https://github.com/EtienneBBeaulac/git-worktrees/issues

---

## 🙏 Thank You!

This release is the result of user feedback requesting a cleaner, simpler experience. We listened, and we hope you love it!

Happy coding! ✨

