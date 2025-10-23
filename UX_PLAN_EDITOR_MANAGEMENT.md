# Comprehensive UX Plan: Editor Management Across All Tools

## Core Principles

1. **First-time clarity** - Clear setup on first use
2. **Speed for regulars** - Fast, non-intrusive for repeat use
3. **Easy overrides** - Simple to change when needed
4. **Consistency** - Same behavior across all commands
5. **Terminal-first** - Great experience for terminal-only users
6. **Discoverable** - Features are easy to find

---

## First-Run Experience (One Time Only)

### Trigger
- No config file exists (`~/.config/git-worktrees/config`)
- AND first time opening a worktree
- Happens in: `wtnew`, `wtopen`, `wt` hub, `wtls --open`

### Flow
```bash
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
  
Choice [1-9]: 1

✓ Saved: Android Studio

  You can change this anytime:
    wt config edit
    export WT_EDITOR="Different Editor"
    wt new feature --app="Other Editor"

Press Enter to continue...
```

**Key points:**
- Only happens ONCE per user
- Creates `~/.config/git-worktrees/config` with choice
- Shows how to change later
- Blocking - requires Enter to continue (so they read it)

---

## Default Behavior (After First Run)

### Silent Auto-Open
All commands **silently** open in configured editor:

```bash
# wt hub
$ wt
✓ Selected: feature/my-branch
🚀 Opening in Android Studio...
```

```bash
# wtnew
$ wt new feature
✓ Creating new branch: feature
...
🚀 Opening in Android Studio...
```

```bash
# wtopen
$ wt open feature
✓ Opening worktree: repo-feature
🚀 Opening in Android Studio...
```

**No prompts** - just works!

---

## Override Methods (Choose What You Want)

### Method 1: Command-Line Flags (Always Available)
```bash
wt new feature --app="Cursor"           # Use Cursor this time
wt new feature --no-open                # Don't open
wtopen feature --app="VS Code"          # Use VS Code
```

**Use case:** One-off changes, scripting

---

### Method 2: Environment Variable (Per Session)
```bash
export WT_EDITOR="Cursor"
wt new feature1     # Opens in Cursor
wt new feature2     # Opens in Cursor
```

**Use case:** Different editor for a work session

---

### Method 3: Actions Menu (Interactive Override)
In `wt` hub, press **Ctrl-A** for actions:

```bash
# During wt hub interaction
📂  Worktrees: feature/my-branch

[Press Ctrl-A]

⚙️  Action:
  Open
  Show path
  Remove
  Change editor         # ← NEW
  Prune stale
  Set upstream

[Select "Change editor"]

Choose editor for this session:
  1) Android Studio (current default)
  2) Cursor
  3) Visual Studio Code
  4) IntelliJ IDEA
  5) PyCharm
  6) None
  
Choice [1-6]: 2
✓ Using Cursor for this session

[Returns to worktree selection, will use Cursor]
```

**Use case:** Want to change mid-flow in interactive hub

---

### Method 4: Configuration File (Permanent Change)
```bash
wt config edit

# Opens: ~/.config/git-worktrees/config
editor=Cursor        # Change this line

# Or via command:
wt config set editor "Cursor"
```

**Use case:** Permanent preference change

---

## Configuration Options

### `~/.config/git-worktrees/config`

```ini
# ============================================================================
# Editor Settings
# ============================================================================
# Your default editor/IDE
editor=Android Studio

# ============================================================================
# Behavior Settings
# ============================================================================
# Auto-open after creating worktree
behavior.autoopen=true

# Prompt behavior: silent, always, first-time
behavior.editor_prompt=silent

# Always push new branches
behavior.autopush=false
```

### Prompt Behavior Options

**`silent`** (default) - No prompts after first-run setup
```bash
$ wt new feature
[creates worktree]
🚀 Opening in Android Studio...
```

**`always`** - Always ask (for users who want control)
```bash
$ wt new feature
[creates worktree]
📂 Open in Android Studio? [Y/e/n]: ___
  Y or Enter  = Use Android Studio
  e           = Choose different editor
  n           = Don't open

Choice: y
🚀 Opening in Android Studio...
```

**`first-time`** (alternative) - Only ask when config changes
```bash
# First use after changing editor
📂 Now using Cursor. Is this correct? [Y/n]: 
```

---

## Tool-Specific Behaviors

### `wt` (Hub)
**Interactive selection:**
1. User selects worktree in FZF
2. Checks actions menu override (Ctrl-A → Change editor)
3. Opens in configured editor silently
4. Or respects `behavior.editor_prompt` setting

**Keyboard shortcuts:**
- `Ctrl-A` → Actions menu (includes "Change editor")
- `Ctrl-H` → Help (shows all shortcuts)

---

### `wtnew` (Create)
**After creation:**
1. Worktree created successfully
2. Opens in configured editor silently
3. Unless `--no-open` flag used
4. Or respects `behavior.editor_prompt` setting

**Flags:**
- `--app="Editor"` - Use specific editor
- `--no-open` - Don't open

---

### `wtopen` (Open Existing)
**After finding worktree:**
1. Worktree located
2. Opens in configured editor silently
3. Unless `--no-open` flag used

**Flags:**
- `--app="Editor"` - Use specific editor
- `--no-open` - Just print path

---

### `wtls --open` (List and Open)
**After selection:**
1. User selects from list
2. Opens in configured editor silently
3. Or respects `behavior.editor_prompt` setting

**Flags:**
- `--app="Editor"` - Use specific editor

---

## Terminal-Only Users

For users who never want IDE opening:

**Option 1: First-run choice**
```bash
Choose your default editor:
  ...
  9) Don't auto-open (show path only)
  
Choice: 9
```

**Option 2: Config**
```bash
behavior.autoopen=false
```

**Result:**
```bash
$ wt new feature
✓ Worktree ready at: /path/to/worktree
```

---

## New Commands

### `wt config set`
Quick configuration without opening editor:

```bash
wt config set editor "Cursor"
wt config set behavior.autoopen false
wt config set behavior.editor_prompt always
```

### `wt config get`
Check current settings:

```bash
$ wt config get editor
Cursor

$ wt config get behavior.autoopen
true
```

---

## Implementation Priority

### Phase 1: Core Experience (v1.1.1)
1. ✅ First-run setup menu
2. ✅ Silent auto-open by default
3. ✅ Config file with `editor=` setting
4. ✅ Respect `--app` and `--no-open` flags
5. ✅ Remove current confusing prompt

### Phase 2: Interactive Overrides (v1.2.0)
6. ✅ Add "Change editor" to Ctrl-A actions menu
7. ✅ Add `behavior.editor_prompt` options
8. ✅ `wt config set/get` commands

### Phase 3: Polish (v1.3.0)
9. Session-based editor override (lasts until shell closes)
10. Better help text showing override methods
11. `wt editors` - Show detected/available editors

---

## User Scenarios

### Scenario 1: New User (Android Studio Developer)
```bash
$ wt new feature
👋 Welcome! Choose default editor:
  1) Android Studio
  ...
Choice: 1
✓ Saved

[opens in Android Studio]
```

**Next time:**
```bash
$ wt new feature2
[creates worktree, opens in Android Studio silently]
```

---

### Scenario 2: Terminal Enthusiast (vim user)
```bash
$ wt new feature
👋 Welcome! Choose default editor:
  ...
  8) vim
  9) Don't auto-open
Choice: 9
✓ Saved

✓ Worktree ready at: /path/to/worktree
```

**Every time after:**
```bash
$ wt new feature2
✓ Worktree ready at: /path/to/worktree
```

---

### Scenario 3: Multi-Tool User (switches between editors)
```bash
# Usually Android Studio, but sometimes Cursor

# Setup default
$ wt config set editor "Android Studio"

# Most of the time
$ wt new feature1
[opens in Android Studio]

# Need Cursor today
$ export WT_EDITOR="Cursor"
$ wt new feature2
[opens in Cursor]

$ wt new feature3
[opens in Cursor]

# Next day (new shell)
$ wt new feature4
[opens in Android Studio again]
```

---

### Scenario 4: Control Freak (wants to confirm every time)
```bash
$ wt config set behavior.editor_prompt always

$ wt new feature
📂 Open in Android Studio? [Y/e/n]: e
Choose: 1) AS 2) Cursor ...
Choice: 2
🚀 Opening in Cursor...

$ wt new feature2
📂 Open in Cursor? [Y/e/n]: y
🚀 Opening in Cursor...
```

---

## Migration from v1.1.0

**Current behavior (v1.1.0):**
- Always prompts: `📂 Open in X? [Y/n/other/save]:`

**New behavior (v1.1.1):**
- First run: Setup menu (if no config)
- After: Silent auto-open
- Same result, less prompting!

**Users with existing config:**
- Keep their saved editor
- New silent behavior
- Can opt into prompts with `behavior.editor_prompt=always`

---

## Summary

### What Users Will Experience

**First Time:**
- Clear setup menu
- Choose once
- Learn how to change

**Regular Use:**
- Fast and silent
- Just works
- No interruptions

**When Needed:**
- Easy flags: `--app="X"`
- Config changes: `wt config edit`
- Interactive override: Actions menu
- Per-session: `export WT_EDITOR`

**Power Users:**
- Full control via config
- Optional prompts
- All tools respect settings
- Consistent everywhere

### Benefits

✅ **Faster** - No prompts for regular use
✅ **Clearer** - First-run setup is obvious
✅ **Flexible** - Multiple override methods
✅ **Consistent** - Works same across all tools
✅ **Discoverable** - Help shows options
✅ **Backward compatible** - Existing config works

---

## Next Steps

1. Implement first-run setup menu
2. Remove current confusing prompt
3. Add silent auto-open as default
4. Add "Change editor" to actions menu
5. Implement `behavior.editor_prompt` options
6. Add `wt config set/get` commands
7. Test with real users
8. Gather feedback
9. Iterate

