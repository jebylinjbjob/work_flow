#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/gh_comment.sh [options]

Options:
  --number <n>          Issue 或 PR 編號（必填）
  --body <text>         留言內容（必填）
  --repo <owner/name>   目標 repo（預設：當前目錄 repo）
  --edit-last           編輯你在該 Issue/PR 的最後一則留言
  --delete-last         刪除你在該 Issue/PR 的最後一則留言
  -h, --help            顯示說明

Example:
  ./scripts/gh_comment.sh --number 42 --body "已修復，請 review"
  ./scripts/gh_comment.sh --number 42 --body "更新內容" --edit-last
  ./scripts/gh_comment.sh --number 42 --delete-last
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
BODY=""
REPO=""
EDIT_LAST=false
DELETE_LAST=false

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --number)
        NUMBER="${2:-}"
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
      --edit-last)
        EDIT_LAST=true
        shift
        ;;
      --delete-last)
        DELETE_LAST=true
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

  if [[ "$EDIT_LAST" == false && "$DELETE_LAST" == false && -z "$BODY" ]]; then
    echo "Error: --body is required (unless using --edit-last or --delete-last)" >&2
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

  if [[ "$DELETE_LAST" == true ]]; then
    echo "Deleting your last comment on #$NUMBER..."
    gh issue comment "$NUMBER" "${repo_flag[@]}" --delete-last
    echo "Comment deleted."
    return
  fi

  if [[ "$EDIT_LAST" == true ]]; then
    echo "Editing your last comment on #$NUMBER..."
    gh issue comment "$NUMBER" "${repo_flag[@]}" --edit-last --body "$BODY"
    echo "Comment updated."
    return
  fi

  echo "Adding comment to #$NUMBER..."
  gh issue comment "$NUMBER" "${repo_flag[@]}" --body "$BODY"
  echo "Comment added."
}

main "$@"
