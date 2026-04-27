#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/gh_issue_create.sh [options]

Options:
  --title <title>       Issue 標題（必填）
  --body <body>         Issue 內容（選填）
  --repo <owner/name>   目標 repo（預設：當前目錄 repo）
  --label <label>       標籤，可多次使用
  --assignee <user>     指派人，可多次使用
  -h, --help            顯示說明

Example:
  ./scripts/gh_issue_create.sh --title "Bug: login failed" --body "Details here" --label bug
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

TITLE=""
BODY=""
REPO=""
LABELS=()
ASSIGNEES=()

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --title)
        TITLE="${2:-}"
        shift 2
        ;;
      --body)
        BODY="${2:-}"
        shift 2
        ;;
      --repo)
        REPO="${2:-}"
        shift 2
        ;;
      --label)
        LABELS+=("${2:-}")
        shift 2
        ;;
      --assignee)
        ASSIGNEES+=("${2:-}")
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

  if [[ -z "$TITLE" ]]; then
    echo "Error: --title is required" >&2
    usage
    exit 1
  fi
}

main() {
  parse_args "$@"
  require_gh

  local cmd=(gh issue create --title "$TITLE")

  if [[ -n "$BODY" ]]; then
    cmd+=(--body "$BODY")
  fi

  if [[ -n "$REPO" ]]; then
    cmd+=(--repo "$REPO")
  fi

  for label in "${LABELS[@]}"; do
    cmd+=(--label "$label")
  done

  for assignee in "${ASSIGNEES[@]}"; do
    cmd+=(--assignee "$assignee")
  done

  echo "Creating issue: $TITLE"
  "${cmd[@]}"
}

main "$@"
