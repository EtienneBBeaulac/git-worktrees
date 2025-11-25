#!/usr/bin/env zsh
# wt-validation.zsh - Input validation and sanitization
# Part of Phase 1: Core Infrastructure

emulate -L zsh
setopt local_options pipefail
unsetopt xtrace verbose

# ============================================================================
# Branch Name Validation (Pure Functions - No Mutable Global State)
# ============================================================================

# Get validation error for a branch name (pure function)
# Usage: error=$(wt_branch_validation_error "name")
# Returns: Error message on stdout if invalid, empty if valid
# Exit code: 0 always (use output to check validity)
wt_branch_validation_error() {
  local name="$1"
  
  [[ -z "$name" ]] && { echo "Branch name cannot be empty"; return 0; }
  [[ "$name" == .* ]] && { echo "Branch name cannot start with '.'"; return 0; }
  [[ "$name" == -* ]] && { echo "Branch name cannot start with '-'"; return 0; }
  [[ "$name" == *..* ]] && { echo "Branch name cannot contain '..'"; return 0; }
  [[ "$name" == *'@{'* ]] && { echo "Branch name cannot contain '@{'"; return 0; }
  [[ "$name" == *' '* ]] && { echo "Branch name cannot contain spaces"; return 0; }
  
  # Special chars check (glob pattern for zsh compatibility)
  if [[ "$name" == *'~'* || "$name" == *'^'* || "$name" == *':'* || 
        "$name" == *'?'* || "$name" == *'*'* || "$name" == *'['* ||
        "$name" == *'\'* || "$name" == *']'* ]]; then
    echo "Branch name contains invalid characters: ~^:?*[\\"
    return 0
  fi
  
  [[ "$name" == *.lock ]] && { echo "Branch name cannot end with '.lock'"; return 0; }
  [[ "$name" == */ ]] && { echo "Branch name cannot end with '/'"; return 0; }
  [[ "$name" == "@" ]] && { echo "Branch name cannot be '@'"; return 0; }
  
  # Valid - no output
  return 0
}

# Validate branch name according to Git rules (uses pure function internally)
# Usage: wt_validate_branch_name <name>
# Returns: 0 if valid, 1 if invalid (error message sent to stderr)
wt_validate_branch_name() {
  local name="$1"
  local error
  error="$(wt_branch_validation_error "$name")"
  
  if [[ -n "$error" ]]; then
    # Output error to stderr so caller can capture it or let it display
    echo "$error" >&2
    return 1
  fi
  return 0
}

# Get branch name validation error message (legacy compatibility)
# Usage: msg=$(wt_validate_branch_name_error <name>)
wt_validate_branch_name_error() {
  local error
  error="$(wt_branch_validation_error "$1")"
  echo "${error:-Branch name is invalid}"
}

# ============================================================================
# Branch Name Sanitization
# ============================================================================

# Sanitize branch name to make it valid
# Usage: wt_sanitize_branch_name <name>
wt_sanitize_branch_name() {
  local name="$1"
  
  # Handle @ alone as special case first
  [[ "$name" == "@" ]] && echo "at" && return 0
  
  # Replace @{ with - and remove closing }
  name="${name//@\{/-}"
  name="${name//\}/}"
  
  # Replace remaining @ with -
  name="${name//@/-}"
  
  # Replace spaces with hyphens
  name="${name// /-}"
  
  # Remove invalid characters (including curly braces that remain)
  name="${name//[~^:?*\[\\\]\{\}]/-}"
  
  # Replace .. with - (repeatedly)
  while [[ "$name" == *..* ]]; do
    name="${name//../-}"
  done
  
  # Remove leading dots
  while [[ "$name" == .* && -n "$name" ]]; do
    name="${name#.}"
  done
  
  # Remove leading hyphens
  while [[ "$name" == -* && -n "$name" ]]; do
    name="${name#-}"
  done
  
  # Remove trailing slashes
  while [[ "$name" == */ && -n "$name" ]]; do
    name="${name%/}"
  done
  
  # Remove trailing hyphens
  while [[ "$name" == *- && -n "$name" ]]; do
    name="${name%-}"
  done
  
  # Remove .lock suffix
  [[ "$name" == *.lock ]] && name="${name%.lock}"
  
  # Ensure not empty or just dots/hyphens
  if [[ -z "$name" ]] || [[ "$name" =~ ^[.-]+$ ]]; then
    name="branch"
  fi
  
  echo "$name"
}

# ============================================================================
# Fuzzy Matching
# ============================================================================

# Find closest matching branch
# Usage: wt_fuzzy_match_branch <input>
# Returns: Best matching branch name
wt_fuzzy_match_branch() {
  local input="$1"
  local branches
  
  # Get all branches
  branches=$(git branch --all --format='%(refname:short)' 2>/dev/null | grep -v '^HEAD$')
  
  [[ -z "$branches" ]] && return 1
  
  # Try exact match first (case insensitive)
  local exact
  exact=$(echo "$branches" | grep -i "^${input}$" | head -1)
  [[ -n "$exact" ]] && echo "$exact" && return 0
  
  # Try prefix match
  local prefix
  prefix=$(echo "$branches" | grep -i "^${input}" | head -1)
  [[ -n "$prefix" ]] && echo "$prefix" && return 0
  
  # Try substring match
  local substring
  substring=$(echo "$branches" | grep -i "$input" | head -1)
  [[ -n "$substring" ]] && echo "$substring" && return 0
  
  # Try Levenshtein distance (simplified: count differing chars)
  local best_match=""
  local best_score=999
  
  while IFS= read -r branch; do
    local score=$(wt_string_distance "$input" "$branch")
    if (( score < best_score )); then
      best_score=$score
      best_match="$branch"
    fi
  done <<< "$branches"
  
  [[ -n "$best_match" ]] && echo "$best_match" && return 0
  
  return 1
}

# Calculate simplified string distance
# Usage: wt_string_distance <str1> <str2>
wt_string_distance() {
  local s1="$1"
  local s2="$2"
  
  # Simplified: just count length difference + char mismatches
  local len1=${#s1}
  local len2=${#s2}
  local distance=$((len1 > len2 ? len1 - len2 : len2 - len1))
  
  local min_len=$((len1 < len2 ? len1 : len2))
  
  for (( i=1; i<=min_len; i++ )); do
    [[ "${s1:i-1:1}" != "${s2:i-1:1}" ]] && ((distance++))
  done
  
  echo "$distance"
}

# ============================================================================
# Worktree Path Validation
# ============================================================================

# Validate worktree path
# Usage: wt_validate_path <path>
wt_validate_path() {
  local path="$1"
  
  # Empty path
  [[ -z "$path" ]] && return 1
  
  # Path already exists
  [[ -e "$path" ]] && return 1
  
  # Parent directory doesn't exist
  local parent="$(dirname "$path")"
  [[ ! -d "$parent" ]] && return 1
  
  # Parent not writable
  [[ ! -w "$parent" ]] && return 1
  
  # Valid
  return 0
}

# Get path validation error message
# Usage: wt_validate_path_error <path>
wt_validate_path_error() {
  local path="$1"
  
  [[ -z "$path" ]] && echo "Path cannot be empty" && return
  [[ -e "$path" ]] && echo "Path already exists: $path" && return
  
  local parent="$(dirname "$path")"
  [[ ! -d "$parent" ]] && echo "Parent directory does not exist: $parent" && return
  [[ ! -w "$parent" ]] && echo "Parent directory is not writable: $parent" && return
  
  echo "Path is invalid"
}

# ============================================================================
# Worktree Path Sanitization
# ============================================================================

# Sanitize path for worktree
# Usage: wt_sanitize_path <base_dir> <branch_name>
wt_sanitize_path() {
  local base_dir="$1"
  local branch="$2"
  
  # Convert slashes in branch name to hyphens for path
  local path_suffix="${branch//\//-}"
  
  # Remove any remaining invalid path characters
  path_suffix="${path_suffix//[^a-zA-Z0-9_-]/-}"
  
  # Build full path
  local full_path="${base_dir}/${path_suffix}"
  
  # If path exists, append counter
  if [[ -e "$full_path" ]]; then
    local counter=1
    while [[ -e "${full_path}-${counter}" ]]; do
      ((counter++))
    done
    full_path="${full_path}-${counter}"
  fi
  
  echo "$full_path"
}

# ============================================================================
# Git Reference Validation
# ============================================================================

# Check if reference exists
# Usage: wt_ref_exists <ref>
wt_ref_exists() {
  local ref="$1"
  git rev-parse --verify --quiet "$ref" >/dev/null 2>&1
}

# Check if branch exists locally
# Usage: wt_branch_exists <branch>
wt_branch_exists() {
  local branch="$1"
  git show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null
}

# Check if branch exists remotely
# Usage: wt_remote_branch_exists <remote> <branch>
wt_remote_branch_exists() {
  local remote="$1"
  local branch="$2"
  git ls-remote --heads "$remote" "$branch" 2>/dev/null | grep -q .
}

# Check if worktree exists at path
# Usage: wt_worktree_exists <path>
wt_worktree_exists() {
  local path="$1"
  # Issue #2 fix - use wrapper function (note: wt_git_worktree_list_porcelain may not be loaded yet)
  git worktree list --porcelain 2>/dev/null | grep -q "^worktree $(cd "$path" 2>/dev/null && pwd)$"
}

# Check if branch is checked out in any worktree
# Usage: wt_branch_checked_out <branch>
wt_branch_checked_out() {
  local branch="$1"
  # Issue #2 fix - keep direct call since wt-common.zsh may not be loaded yet
  git worktree list --porcelain 2>/dev/null | grep -q "^branch refs/heads/$branch$"
}

# ============================================================================
# Input Prompts with Validation
# ============================================================================

# Prompt for valid branch name
# Usage: wt_prompt_branch_name [default]
wt_prompt_branch_name() {
  local default="${1:-}"
  local name
  
  while true; do
    if [[ -n "$default" ]]; then
      printf "Branch name [%s]: " "$default"
    else
      printf "Branch name: "
    fi
    
    read -r name
    
    # Use default if empty
    [[ -z "$name" && -n "$default" ]] && name="$default"
    
    # Validate
    if wt_validate_branch_name "$name"; then
      echo "$name"
      return 0
    else
      local error
      error=$(wt_validate_branch_name_error "$name")
      echo "❌ $error" >&2
      
      # Offer to sanitize
      local sanitized
      sanitized=$(wt_sanitize_branch_name "$name")
      if [[ "$sanitized" != "$name" ]]; then
        echo "   💡 Suggestion: $sanitized" >&2
        printf "   Use suggestion? [Y/n]: "
        local use_suggestion
        read -r use_suggestion
        if [[ "${use_suggestion:l}" != "n" ]]; then
          echo "$sanitized"
          return 0
        fi
      fi
    fi
  done
}

# Prompt for valid path
# Usage: wt_prompt_path [default]
wt_prompt_path() {
  local default="${1:-}"
  local path
  
  while true; do
    if [[ -n "$default" ]]; then
      printf "Path [%s]: " "$default"
    else
      printf "Path: "
    fi
    
    read -r path
    
    # Use default if empty
    [[ -z "$path" && -n "$default" ]] && path="$default"
    
    # Expand ~
    path="${path/#\~/$HOME}"
    
    # Validate
    if wt_validate_path "$path"; then
      echo "$path"
      return 0
    else
      local error
      error=$(wt_validate_path_error "$path")
      echo "❌ $error" >&2
      
      # Offer to sanitize
      if [[ -e "$path" ]]; then
        local counter=1
        local new_path="${path}-${counter}"
        while [[ -e "$new_path" ]]; do
          ((counter++))
          new_path="${path}-${counter}"
        done
        echo "   💡 Suggestion: $new_path" >&2
        printf "   Use suggestion? [Y/n]: "
        local use_suggestion
        read -r use_suggestion
        if [[ "${use_suggestion:l}" != "n" ]]; then
          echo "$new_path"
          return 0
        fi
      fi
    fi
  done
}

# ============================================================================
# Auto-correction Suggestions
# ============================================================================

# Suggest corrections for invalid branch name
# Usage: wt_suggest_branch_corrections <invalid_name>
wt_suggest_branch_corrections() {
  local name="$1"
  local suggestions=()
  
  # Sanitized version
  local sanitized
  sanitized=$(wt_sanitize_branch_name "$name")
  [[ "$sanitized" != "$name" ]] && suggestions+=("$sanitized")
  
  # Fuzzy match existing branches
  local fuzzy
  fuzzy=$(wt_fuzzy_match_branch "$name" 2>/dev/null)
  [[ -n "$fuzzy" && "$fuzzy" != "$sanitized" ]] && suggestions+=("$fuzzy (existing)")
  
  # Common patterns
  if [[ "$name" == */* ]]; then
    # Looks like a path-style branch
    suggestions+=("${name//\//-} (flatten)")
  fi
  
  # Return suggestions
  if (( ${#suggestions[@]} > 0 )); then
    printf '%s\n' "${suggestions[@]}"
    return 0
  fi
  
  return 1
}

# ============================================================================
# Export Functions (silently)
# ============================================================================

{
  typeset -gf wt_validate_branch_name wt_validate_branch_name_error
  typeset -gf wt_sanitize_branch_name
  typeset -gf wt_fuzzy_match_branch wt_string_distance
  typeset -gf wt_validate_path wt_validate_path_error
  typeset -gf wt_sanitize_path
  typeset -gf wt_ref_exists wt_branch_exists wt_remote_branch_exists
  typeset -gf wt_worktree_exists wt_branch_checked_out
  typeset -gf wt_prompt_branch_name wt_prompt_path
  typeset -gf wt_suggest_branch_corrections
} >/dev/null 2>&1

