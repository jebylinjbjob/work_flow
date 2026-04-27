#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/gh_pr_create.sh [options]

Options:
  --title <title>       PR 標題（必填）
  --body <body>         PR 內容（選填）
  --base <branch>       目標分支（預設：main）
  --head <branch>       來源分支（預設：當前分支）
  --repo <owner/name>   目標 repo（預設：當前目錄 repo）
  --draft               建立 draft PR
  --label <label>       標籤，可多次使用
  --reviewer <user>     審查者，可多次使用
  -h, --help            顯示說明

Example:
  ./scripts/gh_pr_create.sh --title "feat: add login" --base main --draft
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
BASE="main"
HEAD=""
REPO=""
DRAFT=false
LABELS=()
REVIEWERS=()

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
      --base)
        BASE="${2:-}"
        shift 2
        ;;
      --head)
        HEAD="${2:-}"
        shift 2
        ;;
      --repo)
        REPO="${2:-}"
        shift 2
        ;;
      --draft)
        DRAFT=true
        shift
        ;;
      --label)
        LABELS+=("${2:-}")
        shift 2
        ;;
      --reviewer)
        REVIEWERS+=("${2:-}")
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

  local cmd=(gh pr create --title "$TITLE" --base "$BASE")

  if [[ -n "$BODY" ]]; then
    cmd+=(--body "$BODY")
  fi

  if [[ -n "$HEAD" ]]; then
    cmd+=(--head "$HEAD")
  fi

  if [[ -n "$REPO" ]]; then
    cmd+=(--repo "$REPO")
  fi

  if [[ "$DRAFT" == true ]]; then
    cmd+=(--draft)
  fi

  for label in "${LABELS[@]}"; do
    cmd+=(--label "$label")
  done

  for reviewer in "${REVIEWERS[@]}"; do
    cmd+=(--reviewer "$reviewer")
  done

  echo "Creating PR: $TITLE"
  "${cmd[@]}"
}

main "$@"
