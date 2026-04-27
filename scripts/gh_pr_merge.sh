#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/gh_pr_merge.sh [options]

Options:
  --number <n>          PR 編號（必填）
  --repo <owner/name>   目標 repo（預設：當前目錄 repo）
  --method <method>     合併方式：merge | squash | rebase（預設：merge）
  --delete-branch       合併後刪除來源分支
  --auto                啟用 auto-merge（等 CI 通過後自動合併）
  -h, --help            顯示說明

Example:
  ./scripts/gh_pr_merge.sh --number 42 --method squash --delete-branch
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
METHOD="merge"
DELETE_BRANCH=false
AUTO=false

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
      --method)
        METHOD="${2:-}"
        shift 2
        ;;
      --delete-branch)
        DELETE_BRANCH=true
        shift
        ;;
      --auto)
        AUTO=true
        shift
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

  case "$METHOD" in
    merge | squash | rebase) ;;
    *)
      echo "Error: --method must be merge, squash, or rebase" >&2
      exit 1
      ;;
  esac
}

main() {
  parse_args "$@"
  require_gh

  local cmd=(gh pr merge "$NUMBER")

  if [[ -n "$REPO" ]]; then
    cmd+=(--repo "$REPO")
  fi

  case "$METHOD" in
    merge) cmd+=(--merge) ;;
    squash) cmd+=(--squash) ;;
    rebase) cmd+=(--rebase) ;;
  esac

  if [[ "$DELETE_BRANCH" == true ]]; then
    cmd+=(--delete-branch)
  fi

  if [[ "$AUTO" == true ]]; then
    cmd+=(--auto)
  fi

  echo "Merging PR #$NUMBER (method: $METHOD)..."
  "${cmd[@]}"
  echo "PR #$NUMBER merged."
}

main "$@"
