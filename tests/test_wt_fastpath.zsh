#!/usr/bin/env zsh
set -euo pipefail

# Simulate `git worktree list --porcelain` output and verify the awk logic
local selectable
selectable=$(awk '
  BEGIN{
    print "worktree /tmp/repo";
    print "branch refs/heads/main";
    print "";
    print "worktree /tmp/feature";
    print "branch refs/heads/feature/test";
    print "";
  }' | awk -v show_det=0 '
      BEGIN{d="";b="";det=0}
      function flush(){
        if(d!=""){
          if(b!="" && det==0){ gsub(/^refs\/heads\//,"",b); print b "\t" d }
          else if(det==1 && show_det==1){ print "(detached)\t" d }
          d=""; b=""; det=0
        }
      }
      /^worktree /{flush(); d=$2; next}
      /^branch /  {b=$2; next}
      /^detached/ {det=1; next}
      /^$/        {flush()}
      END         {flush()}
    ')

# Expect two rows and correct stripping of refs/heads/
[[ $(echo "$selectable" | wc -l | tr -d ' ') == 2 ]]
[[ $(echo "$selectable" | head -n1 | cut -f1) == "main" ]]
[[ $(echo "$selectable" | tail -n1 | cut -f1) == "feature/test" ]]

echo "wt fastpath test OK"
