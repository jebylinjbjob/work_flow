#!/usr/bin/env bash
set -euo pipefail

STATE="open"
REPO=""
LIMIT="20"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/gh_overview.sh [options]

Options:
  --state <open|closed|all>   Filter by state (default: open)
  --repo <owner/name>         Limit to one repository
  --limit <n>                 Number of items to display per section (default: 20)
  -h, --help                  Show this help message

Requirements:
  - gh CLI installed
  - gh auth login completed
EOF
}

require_gh() {
  if ! command -v gh >/dev/null 2>&1; then
    echo "Error: gh CLI is not installed." >&2
    echo "Install: https://cli.github.com/" >&2
    exit 1
  fi

  if ! gh auth status >/dev/null 2>&1; then
    echo "Error: GitHub auth not found." >&2
    echo "Please run: gh auth login" >&2
    exit 1
  fi
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --state)
        STATE="${2:-}"
        shift 2
        ;;
      --repo)
        REPO="${2:-}"
        shift 2
        ;;
      --limit)
        LIMIT="${2:-}"
        shift 2
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        echo "Unknown option: $1" >&2
        usage
        exit 1
        ;;
    esac
  done

  case "$STATE" in
    open | closed | all) ;;
    *)
      echo "Error: --state must be open, closed, or all" >&2
      exit 1
      ;;
  esac

  if ! [[ "$LIMIT" =~ ^[0-9]+$ ]] || [[ "$LIMIT" -lt 1 ]]; then
    echo "Error: --limit must be a positive integer" >&2
    exit 1
  fi

  if [[ -n "$REPO" ]] && ! [[ "$REPO" =~ ^[^/]+/[^/]+$ ]]; then
    echo "Error: --repo must be in owner/name format" >&2
    exit 1
  fi
}

state_qualifier() {
  case "$STATE" in
    open) echo "is:open" ;;
    closed) echo "is:closed" ;;
    all) echo "" ;;
  esac
}

repo_qualifier() {
  if [[ -n "$REPO" ]]; then
    echo "repo:${REPO}"
  else
    echo ""
  fi
}

normalize_query() {
  # Collapse duplicate spaces for clean search query.
  echo "$*" | awk '{$1=$1; print}'
}

search_count() {
  local query="$1"
  gh api -X GET search/issues -f q="$query" -f per_page="$LIMIT" --jq '.total_count'
}

print_items_table() {
  local title="$1"
  local query="$2"
  local count="$3"

  echo
  echo "$title"
  echo "------------------------------------------------------------"

  if [[ "$count" == "0" ]]; then
    echo "No records."
    return
  fi

  gh api -X GET search/issues -f q="$query" -f per_page="$LIMIT" --jq '
    .items[] |
    [
      (if .pull_request then "PR" else "Issue" end),
      (.number|tostring),
      (.repository_url | split("/") | .[-2] + "/" + .[-1]),
      .state,
      .updated_at,
      (.title | gsub("[\\t\\r\\n]"; " "))
    ] | @tsv
  ' | awk 'BEGIN {print "Type\t#\tRepo\tState\tUpdated\tTitle"} {print}' | column -t -s $'\t'
}

main() {
  parse_args "$@"
  require_gh

  local login state_q repo_q issue_query pr_query
  login="$(gh api user --jq '.login')"
  state_q="$(state_qualifier)"
  repo_q="$(repo_qualifier)"

  issue_query="$(normalize_query is:issue -is:pr involves:@me "$state_q" "$repo_q")"
  pr_query="$(normalize_query is:pr involves:@me "$state_q" "$repo_q")"

  local issue_count pr_count
  issue_count="$(search_count "$issue_query")"
  pr_count="$(search_count "$pr_query")"

  echo "GitHub overview"
  echo "User: ${login}"
  echo "State: ${STATE}"
  if [[ -n "$REPO" ]]; then
    echo "Repository: ${REPO}"
  else
    echo "Repository: all"
  fi
  echo "Issues total: ${issue_count}"
  echo "PRs total: ${pr_count}"

  print_items_table "Issues" "$issue_query" "$issue_count"
  print_items_table "Pull Requests" "$pr_query" "$pr_count"
}

main "$@"
