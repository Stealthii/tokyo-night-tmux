#!/usr/bin/env bash

# Check if enabled
ENABLED=$(tmux show-option -gv @tokyo-night-tmux_show_wbg 2>/dev/null)
[[ ${ENABLED} -ne 1 ]] && exit 0

# Imports
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
source "$ROOT_DIR/src/themes.sh"
source "$ROOT_DIR/lib/git.sh"

cd "$1" || exit 1
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
[[ -z $BRANCH ]] && exit 0
PROVIDER=$(get_provider)
PROVIDER_ICON=$(get_provider_icon "$PROVIDER")

PR_COUNT=0
REVIEW_COUNT=0
ISSUE_COUNT=0
BUG_COUNT=0

PR_STATUS=""
REVIEW_STATUS=""
ISSUE_STATUS=""
BUG_STATUS=""

if [[ $PROVIDER == *"github"* ]]; then
  if ! command -v gh &>/dev/null; then
    exit 1
  fi
  PR_COUNT=$(gh pr list --json number --jq 'length')
  REVIEW_COUNT=$(gh pr status --json reviewRequests --jq '.needsReview | length')
  RES=$(gh issue list --json "assignees,labels" --assignee @me)
  ISSUE_COUNT=$(echo "$RES" | jq 'length' | bc)
  BUG_COUNT=$(echo "$RES" | jq 'map(select(.labels[].name == "bug")) | length' | bc)
  ISSUE_COUNT=$((ISSUE_COUNT - BUG_COUNT))
elif [[ $PROVIDER == *"gitlab"* ]]; then
  if ! command -v glab &>/dev/null; then
    exit 1
  fi
  PR_COUNT=$(glab mr list | grep -cE "^\!")
  REVIEW_COUNT=$(glab mr list --reviewer=@me | grep -cE "^\!")
  BUG_COUNT=$(glab issue list -t incident | grep -cE "^\#")
  ISSUE_COUNT=$(glab issue list -t issue | grep -cE "^\#")
else
  exit 0
fi

if [[ $PR_COUNT -gt 0 ]]; then
  PR_STATUS="#[fg=${THEME[ghgreen]},bg=${THEME[background]},bold] ${RESET}${PR_COUNT} "
fi

if [[ $REVIEW_COUNT -gt 0 ]]; then
  REVIEW_STATUS="#[fg=${THEME[ghyellow]},bg=${THEME[background]},bold] ${RESET}${REVIEW_COUNT} "
fi

if [[ $ISSUE_COUNT -gt 0 ]]; then
  ISSUE_STATUS="#[fg=${THEME[ghgreen]},bg=${THEME[background]},bold] ${RESET}${ISSUE_COUNT} "
fi

if [[ $BUG_COUNT -gt 0 ]]; then
  BUG_STATUS="#[fg=${THEME[ghred]},bg=${THEME[background]},bold] ${RESET}${BUG_COUNT} "
fi

if [[ $PR_COUNT -gt 0 || $REVIEW_COUNT -gt 0 || $ISSUE_COUNT -gt 0 ]]; then
  WB_STATUS="#[fg=${THEME[black]},bg=${THEME[background]},bold] ${RESET}#[fg=${THEME[foreground]}]$PROVIDER_ICON $RESET$PR_STATUS$REVIEW_STATUS$ISSUE_STATUS$BUG_STATUS"
fi

echo "$WB_STATUS"

# Wait extra time if status-interval is less than 30 seconds to
# avoid to overload GitHub API
INTERVAL=$(tmux display -p '#{status-interval}')
if [[ $INTERVAL -lt 20 ]]; then
  sleep 20
fi
