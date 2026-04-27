#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/gh_notifications.sh [options]

Options:
  --all                 顯示所有通知（包含已讀）
  --repo <owner/name>   只看特定 repo 的通知
  --limit <n>           顯示筆數（預設：20）
  -h, --help            顯示說明

Example:
  ./scripts/gh_notifications.sh --all --limit 50
  ./scripts/gh_notifications.sh --repo jebylinjbjob/work_flow
EOF
}

require_gh() {
  if ! command -v gh >/dev/null 2>&1; then
    echo "Error: gh CLI is not installed." >&2
    exit 1
  fi
  if ! gh auth status >/dev/null 2>&1; then
    echo "Error: Please run 'gh auth login' first." >&2
    exit 1
  fi
}

ALL=false
REPO=""
LIMIT="20"

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --all)
        ALL=true
        shift
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
}

main() {
  parse_args "$@"
  require_gh

  echo "============================================================"
  echo "GitHub Notifications"
  echo "============================================================"

  local endpoint="notifications?per_page=${LIMIT}"
  if [[ "$ALL" == true ]]; then
    endpoint="${endpoint}&all=true"
  fi

  local notifications
  notifications="$(gh api "$endpoint")"

  local count
  count="$(echo "$notifications" | gh api --input - --jq 'length' 2>/dev/null || echo "0")"

  if [[ "$count" == "0" ]]; then
    echo "No notifications."
    return
  fi

  echo "$notifications" | gh api --input - --jq '
    .[] |
    [
      .reason,
      (.repository.full_name // "unknown"),
      (.subject.type // "unknown"),
      (.subject.title // "No title"),
      .updated_at
    ] | @tsv
  ' | {
    if [[ -n "$REPO" ]]; then
      grep "$REPO" || true
    else
      cat
    fi
  } | awk 'BEGIN {print "Reason\tRepo\tType\tTitle\tUpdated"} {print}' | column -t -s $'\t'
}

main "$@"
