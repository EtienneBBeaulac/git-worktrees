Contributing

Environment parity
- Tests run in a normalized environment to match CI:
  - LC_ALL=C, LANG=C, TZ=UTC
  - GIT_CONFIG_NOSYSTEM=1, GIT_CONFIG_GLOBAL=/dev/null, GIT_TEMPLATE_DIR=/dev/null
  - HOME set to a temp dir per test; scripts invoked via `zsh -f` (no rc files)
- fzf/open/pbcopy are stubbed in PATH for E2E tests; non-fzf paths use stdin piping.
- Paths and SHAs are redacted in snapshot-like assertions; avoid relying on absolute paths.

Running tests
- Full suite: `make test` (or `bash tests/run.sh`)
- Fast subset: `make test-fast` (runs unit helpers + a few E2E smoke tests)

CI
- GitHub Actions runs a fast job and a full matrix (macOS/Ubuntu; with/without fzf).
- The workflow prints tool versions (zsh/git/awk) and PATH to aid debugging.

Style and portability
- Prefer awk/sed that work on GNU and BSD; keep awk programs in single-quoted blocks.
- Keep zsh tests/scripts lintable; use a zsh shebang where appropriate.

Zsh heredoc quirk (IMPORTANT)
- **Do NOT** use `cat <<EOF` (unquoted) after a `local` declaration inside `case` branches.
- This combination triggers a zsh 5.9 parser bug where the `;;` terminator gets placed on
  the same line as the heredoc, corrupting the output.

  ```zsh
  # BAD - will fail with "command not found: cat"
  case "$1" in
    test)
      local path="$1"
      cat <<EOF
  Path: $path
  EOF
      ;;
  esac

  # GOOD - use print -r instead
  case "$1" in
    test)
      local path="$1"
      print -r -- "Path: $path"
      ;;
  esac

  # ALSO GOOD - quoted heredoc (but no variable expansion)
  case "$1" in
    test)
      cat <<'EOF'
  Static content only
  EOF
      ;;
  esac

  # ALSO GOOD - build message, output after case
  case "$1" in
    test)
      local path="$1"
      msg="Path: $path"
      ;;
  esac
  [[ -n "$msg" ]] && echo "$msg"
  ```

- See `scripts/lib/wt-discovery.zsh` for the canonical pattern using `print -r -- $'...'`.

