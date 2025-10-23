# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.1] - 2025-01-XX

### Added

#### First-Run Setup Experience
- **One-time welcome menu** on first use: Choose from 9 popular editors (Android Studio, VS Code, Cursor, IntelliJ IDEA, PyCharm, WebStorm, Sublime Text, vim, or "Don't auto-open")
- Takes 5 seconds, runs once, saves your preference
- Clear instructions on how to change editor anytime

#### Enhanced Config Management
- **`wt config set <key> <value>`** - Set config values from CLI
- **`wt config get <key>`** - Get current config values
- Supports `editor`, `behavior.autoopen`, `behavior.editor_prompt` keys
- Easy config updates without opening files

#### Change Editor Anytime
- **"Change editor" option in Ctrl-A actions menu** (wt hub)
- Interactive menu with 9 popular editors
- Instant save to config
- No need to edit config file manually

### Changed

#### Silent Auto-Open (Major UX Improvement)
- **Removed confusing confirmation prompt** from wtnew
- Editor now opens automatically (silent)
- Much faster, cleaner workflow
- Change editor with: `wt config set editor "Different Editor"` or Ctrl-A → "Change editor"

#### Simplified Workflow
- First-time users: Choose editor once → Done
- Regular users: Commands just work (no prompts)
- Power users: `wt config set` for quick changes

### Documentation
- README updated with first-run setup info
- Added config management examples
- Highlighted editor change options
- Updated hub actions menu documentation

---

## [1.1.0] - 2025-01-XX

### Added

#### UX: Selection Visibility
- FZF selections now echo to terminal after selection for complete workflow visibility
- Branch selection shows: "✓ Selected: branch-name" or "✓ Creating new branch: name"
- Base ref selection shows: "✓ Base: origin/main"
- Worktree selection in hub shows: "✓ Selected: branch-name"
- All selections maintain terminal history for debugging and understanding

#### UX: Editor Confirmation
- Interactive editor confirmation prompt before opening: `📂 Open in [editor]? [Y/n/other/save]:`
- Options to choose different editor from menu (9 popular editors)
- Option to save preference as default
- Skip prompt with `WTNEW_SKIP_EDITOR_CONFIRM=1` environment variable

#### Git-Style Subcommands
- **New subcommand interface**: `wt new`, `wt remove`, `wt open`, `wt list`, `wt prune`
- Short aliases for subcommands: `wt n`, `wt rm`, `wt o`, `wt ls`
- `wt config` subcommand for configuration management:
  - `wt config edit` - Open config in editor
  - `wt config show` - Display current configuration
  - `wt config init` - Initialize config with defaults
- `wt help` subcommand for comprehensive documentation
- Enhanced `wt --help` with subcommand overview

#### First-Run Experience
- Welcome message when no worktrees exist, explaining what worktrees are
- Clear guidance on getting started with examples
- Pointer to interactive tutorial

#### Interactive Tutorial
- `wt --tutorial` flag for step-by-step introduction
- 4-part walkthrough covering:
  1. What are worktrees and why use them
  2. How to create worktrees
  3. Managing worktrees (commands and keyboard shortcuts)
  4. Quick start workflow and tips
- Skippable at any point for experienced users

#### Better Error Messages
- Actionable error messages with helpful suggestions
- `wt_error_not_git_repo()` - Explains git repositories with examples
- `wt_error_fzf_missing()` - Installation instructions for fzf
- `wt_error_branch_exists()` - Suggests alternatives when branch exists
- All errors include "Try:" sections with concrete next steps

#### Configuration Management
- Extended config file support at `~/.config/git-worktrees/config`
- Auto-creation with smart defaults on first run
- Configuration options for:
  - Editor/IDE selection
  - Auto-open behavior
  - Auto-push for new branches
  - Worktree reuse preferences
  - UI settings (FZF height, shortcuts visibility)
- Priority system: command flags > env vars > config file
- `wt_load_full_config()` function to load all settings
- `wt_init_config()` for guided setup

#### Tests
- Comprehensive Phase 2 test coverage:
  - `test_phase2_subcommands.zsh` - Subcommand dispatch and aliases
  - `test_phase2_error_messages.zsh` - Error helper functions
  - `test_phase2_config.zsh` - Config management
  - `test_phase2_backward_compat.zsh` - Backward compatibility
- 25 new automated tests ensuring feature stability

### Changed

#### Documentation
- README restructured with clearer hierarchy:
  1. Interactive hub (primary feature)
  2. Subcommands (recommended interface)
  3. Quick access shortcuts (convenience)
- Commands section emphasizes hub-first workflow
- Quick Start updated to showcase both hub and subcommands
- Usage examples modernized with subcommand style
- Homebrew installation moved to top (recommended method)
- Removed unnecessary shell restart note for Homebrew users

#### User Experience
- All commands use consistent error messaging
- Help text updated across all commands to mention subcommands
- Version flag (`--version`) standardized across all commands
- Configuration documentation integrated into README

### Maintained

#### Backward Compatibility
- All original commands still work: `wtnew`, `wtrm`, `wtopen`, `wtls`
- No breaking changes to existing workflows
- Original command-line flags preserved
- Standalone commands positioned as "quick access" shortcuts
- Full compatibility with v1.0.x usage patterns

### Fixed
- **Critical:** Editor opening logic now respects detected/chosen editor
  - Fixed `wt_open_in_android_studio()` to only use `studio` command for Android Studio
  - Fixed fallback logic in `wtnew`, `wtopen` to respect app choice
  - Prevents wrong application from opening (e.g., Android Studio opening when Cursor selected)
- Improved editor detection with smart fallbacks
- Better handling of missing FZF with clear user guidance
- More consistent error handling across all commands
- Missing editor in `wtls --open` now shows helpful message instead of failing silently

---

## [1.0.3] - 2025-01-XX (Phase 1)

### Added
- Smart editor detection (`wt_detect_editor()`)
  - Respects `$WT_EDITOR`, `$WT_APP`, `$VISUAL`, `$EDITOR`
  - Auto-detects GUI editors (VS Code, IntelliJ, PyCharm, etc.)
  - Falls back to CLI editors (vim, nvim, nano)
- First-run editor selection prompt with config persistence
- `--version` flag for all commands

### Changed
- Replaced hardcoded "Android Studio" with smart editor detection
- README updated with "Why Git Worktrees?" section
- Clear before/after examples showing benefits
- Updated documentation to be editor-agnostic
- Homebrew installation simplified (zero configuration)

### Fixed
- README no longer shows outdated `.zshrc` sourcing instructions for Homebrew

---

## [1.0.2] - 2024-XX-XX

### Changed
- Refactored Homebrew Formula to install executable wrappers in `bin/`
- Eliminated need for manual `.zshrc` configuration with Homebrew
- Commands automatically available in PATH after `brew install`
- Updated caveats message for better user experience

---

## [1.0.1] - 2024-XX-XX

### Added
- "Remove all detached" option in `wt` hub actions menu
- "Remove all detached" option in `wtrm` interactive picker
- `wtrm --rm-detached` flag for bulk removal of detached worktrees
- Keyboard shortcuts header in FZF interface

### Changed
- Updated help text and documentation for new detached worktree features

---

## [1.0.0] - 2024-XX-XX

### Added
- Initial release
- `wt` - Interactive hub for managing worktrees
- `wtnew` - Create/open worktrees with smart branch detection
- `wtrm` - Safely remove worktrees with guards
- `wtopen` - Open existing worktrees
- `wtls` - List worktrees with status
- FZF integration for interactive selection
- Android Studio integration
- Recovery and validation modules
- Comprehensive test suite

---

[1.1.0]: https://github.com/EtienneBBeaulac/git-worktrees/compare/v1.0.3...v1.1.0
[1.0.3]: https://github.com/EtienneBBeaulac/git-worktrees/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/EtienneBBeaulac/git-worktrees/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/EtienneBBeaulac/git-worktrees/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/EtienneBBeaulac/git-worktrees/releases/tag/v1.0.0

