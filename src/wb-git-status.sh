#!/usr/bin/env bash

cd "$1" || exit 1
RESET="#[fg=brightwhite,bg=#15161e,nobold,noitalics,nounderscore,nodim,nostrikethrough]"
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
PROVIDER=$(git config remote.origin.url | awk -F '@|:' '{print $2}')

PROVIDER_ICON=""

PR_COUNT=0
REVIEW_COUNT=0
ISSUE_COUNT=0

PR_STATUS=""
REVIEW_STATUS=""
ISSUE_STATUS=""

if [[ -n $BRANCH ]]; then
  exit 0
fi

if [[ $PROVIDER == "github.com" ]]; then
  if ! command -v gh &>/dev/null; then
    exit 1
  fi
  PROVIDER_ICON="$RESET#[fg=#fafafa] "
  PR_COUNT=$(gh pr list --json number --jq 'length' | bc)
  REVIEW_COUNT=$(gh pr status --json reviewRequests --jq '.needsReview | length' | bc)
  ISSUE_COUNT=$(gh issue status --json assignees --jq '.assigned | length' | bc)
elif [[ $PROVIDER == "gitlab.com" ]]; then
  if ! command -v glab &>/dev/null; then
    exit 1
  fi
  PROVIDER_ICON="$RESET#[fg=#fc6d26] "
  PR_COUNT=$(glab mr list | grep -cE "^\!")
  REVIEW_COUNT=$(glab mr list --reviewer=@me | grep -cE "^\!")
  ISSUE_COUNT=$(glab issue list | grep -cE "^\#")
else
  exit 0
fi

if [[ $PR_COUNT -gt 0 ]]; then
  PR_STATUS="#[fg=#3fb950,bg=#15161e,bold] ${RESET}${PR_COUNT} "
fi

if [[ $REVIEW_COUNT -gt 0 ]]; then
  REVIEW_STATUS="#[fg=#d29922,bg=#15161e,bold] ${RESET}${REVIEW_COUNT} "
fi

if [[ $ISSUE_COUNT -gt 0 ]]; then
  ISSUE_STATUS="#[fg=#3fb950,bg=#15161e,bold] ${RESET}${ISSUE_COUNT} "
fi

if [[ $PR_COUNT -gt 0 || $REVIEW_COUNT -gt 0 || $ISSUE_COUNT -gt 0 ]]; then
  WB_STATUS="#[fg=#464646,bg=#15161e,bold] $RESET$PROVIDER_ICON $RESET$PR_STATUS$REVIEW_STATUS$ISSUE_STATUS"
fi

echo "$WB_STATUS"

# Wait extra time if status-interval is less than 30 seconds to
# avoid to overload GitHub API
INTERVAL=$(tmux display -p '#{status-interval}')
if [[ $INTERVAL -lt 20 ]]; then
  sleep 20
fi
