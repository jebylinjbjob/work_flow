#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/gh_branch.sh [options]

Options:
  --list                列出所有分支
  --create <name>       建立新分支
  --checkout <name>     切換到分支
  --delete <name>       刪除分支
  --from <branch>       建立分支時的來源（預設：當前分支）
  -h, --help            顯示說明

Example:
  ./scripts/gh_branch.sh --list
  ./scripts/gh_branch.sh --create feature/login --from main
  ./scripts/gh_branch.sh --checkout feature/login
  ./scripts/gh_branch.sh --delete feature/old
EOF
}

ACTION=""
BRANCH_NAME=""
FROM_BRANCH=""

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --list)
        ACTION="list"
        shift
        ;;
      --create)
        ACTION="create"
        BRANCH_NAME="${2:-}"
        shift 2
        ;;
      --checkout)
        ACTION="checkout"
        BRANCH_NAME="${2:-}"
        shift 2
        ;;
      --delete)
        ACTION="delete"
        BRANCH_NAME="${2:-}"
        shift 2
        ;;
      --from)
        FROM_BRANCH="${2:-}"
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

  if [[ -z "$ACTION" ]]; then
    echo "Error: Please specify an action (--list, --create, --checkout, --delete)" >&2
    usage
    exit 1
  fi
}

main() {
  parse_args "$@"

  case "$ACTION" in
    list)
      echo "Local branches:"
      git branch -a --format='%(refname:short) %(upstream:short) %(committerdate:relative)'
      ;;
    create)
      if [[ -z "$BRANCH_NAME" ]]; then
        echo "Error: branch name is required for --create" >&2
        exit 1
      fi
      if [[ -n "$FROM_BRANCH" ]]; then
        echo "Creating branch '$BRANCH_NAME' from '$FROM_BRANCH'..."
        git checkout -b "$BRANCH_NAME" "$FROM_BRANCH"
      else
        echo "Creating branch '$BRANCH_NAME' from current branch..."
        git checkout -b "$BRANCH_NAME"
      fi
      echo "Branch '$BRANCH_NAME' created and checked out."
      ;;
    checkout)
      if [[ -z "$BRANCH_NAME" ]]; then
        echo "Error: branch name is required for --checkout" >&2
        exit 1
      fi
      echo "Switching to branch '$BRANCH_NAME'..."
      git checkout "$BRANCH_NAME"
      echo "Now on branch '$BRANCH_NAME'."
      ;;
    delete)
      if [[ -z "$BRANCH_NAME" ]]; then
        echo "Error: branch name is required for --delete" >&2
        exit 1
      fi
      echo "Deleting branch '$BRANCH_NAME'..."
      git branch -d "$BRANCH_NAME"
      echo "Branch '$BRANCH_NAME' deleted."
      ;;
  esac
}

main "$@"
