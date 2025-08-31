#!/usr/bin/env bash
set -euo pipefail

install_stubs() {
  local dest="$1"
  mkdir -p "$dest"
  # fzf: captures stdin to numbered files and emits provided selection
  cat > "$dest/fzf" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
COUNT_FILE="${TEST_TMP:-/tmp}/fzf_count"
IN_NUM=1
if [[ -f "$COUNT_FILE" ]]; then IN_NUM=$(( $(cat "$COUNT_FILE") + 1 )); fi
echo -n "$IN_NUM" > "$COUNT_FILE"
IN_FILE="${TEST_TMP:-/tmp}/fzf_call${IN_NUM}_in.txt"
cat > "$IN_FILE"
if [[ -n "${FZF_STUB_LINES:-}" ]]; then
  # First line: key; second line: selected row
  printf "%s\n" "${FZF_STUB_LINES%%$'\n'*}" || true
  printf "%s\n" "${FZF_STUB_LINES#*$'\n'}" || true
  exit 0
fi
exit 1
EOF
  chmod +x "$dest/fzf"

  # open: log target path
  cat > "$dest/open" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf "%s\n" "$*" >> "${TEST_TMP:-/tmp}/open_calls.txt"
exit 0
EOF
  chmod +x "$dest/open"

  # pbcopy: write to a file
  cat > "$dest/pbcopy" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cat > "${TEST_TMP:-/tmp}/pbcopy.txt"
EOF
  chmod +x "$dest/pbcopy"

  # xdg-open: log target path similar to open
  cat > "$dest/xdg-open" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf "%s\n" "$*" >> "${TEST_TMP:-/tmp}/xdgopen_calls.txt"
exit 0
EOF
  chmod +x "$dest/xdg-open"
}
