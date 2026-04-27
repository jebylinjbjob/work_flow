#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/gh_pr_status.sh [options]

Options:
  --number <n>          PR 編號（選填，預設顯示當前分支的 PR）
  --repo <owner/name>   目標 repo（預設：當前目錄 repo）
  -h, --help            顯示說明

Example:
  ./scripts/gh_pr_status.sh --number 42
  ./scripts/gh_pr_status.sh               # 顯示當前分支的 PR
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

  local repo_flag=()
  if [[ -n "$REPO" ]]; then
    repo_flag=(--repo "$REPO")
  fi

  echo "============================================================"
  echo "PR Status"
  echo "============================================================"

  if [[ -n "$NUMBER" ]]; then
    echo "PR #$NUMBER details:"
    gh pr view "$NUMBER" "${repo_flag[@]}"
    echo
    echo "Checks:"
    gh pr checks "$NUMBER" "${repo_flag[@]}" || echo "(No checks configured)"
  else
    echo "Current branch PR status:"
    gh pr status "${repo_flag[@]}"
  fi
}

main "$@"
