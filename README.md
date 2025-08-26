# git-worktrees

Simple shell helpers for Git worktrees:

- `wtnew` – create/open a worktree for a new **or existing** branch (fzf picker, Android Studio auto-open)
- `wtrm`  – safely remove a worktree (fzf preview, guards against uncommitted/unpushed work)

## Install

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/<you>/git-worktrees/main/install.sh)"
```

Usage

wtnew
wtnew -n feature/x -b origin/main --no-open
wtrm
wtrm -d ../repo-feature-x --delete-branch

Requirements
	•	git
	•	fzf (optional, recommended)

License

MIT ©  

---
