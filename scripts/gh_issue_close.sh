#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/gh_issue_close.sh [options]

Options:
  --number <n>          Issue 編號（必填）
  --repo <owner/name>   目標 repo（預設：當前目錄 repo）
  --reason <reason>     關閉原因：completed | not_planned（預設：completed）
  --comment <text>      關閉前留言
  -h, --help            顯示說明

Example:
  ./scripts/gh_issue_close.sh --number 42 --reason completed --comment "Fixed in PR #45"
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

NUMBER=""
REPO=""
REASON="completed"
COMMENT=""

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --number)
        NUMBER="${2:-}"
        shift 2
        ;;
      --repo)
        REPO="${2:-}"
        shift 2
        ;;
      --reason)
        REASON="${2:-}"
        shift 2
        ;;
      --comment)
        COMMENT="${2:-}"
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

  if [[ -z "$NUMBER" ]]; then
    echo "Error: --number is required" >&2
    usage
    exit 1
  fi
}

main() {
  parse_args "$@"
  require_gh

  local repo_flag=()
  if [[ -n "$REPO" ]]; then
    repo_flag=(--repo "$REPO")
  fi

  if [[ -n "$COMMENT" ]]; then
    echo "Adding comment to issue #$NUMBER..."
    gh issue comment "$NUMBER" "${repo_flag[@]}" --body "$COMMENT"
  fi

  echo "Closing issue #$NUMBER (reason: $REASON)..."
  gh issue close "$NUMBER" "${repo_flag[@]}" --reason "$REASON"
  echo "Issue #$NUMBER closed."
}

main "$@"
