#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/gh_clone.sh [options]

Options:
  --repo <owner/name>   要 clone 的 repo（必填）
  --dir <directory>     clone 到的目錄（預設：repo 名稱）
  --depth <n>           shallow clone 深度（選填）
  --branch <branch>     指定分支（選填）
  -h, --help            顯示說明

Example:
  ./scripts/gh_clone.sh --repo microsoft/vscode
  ./scripts/gh_clone.sh --repo microsoft/vscode --dir my-vscode --depth 1
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

REPO=""
DIR=""
DEPTH=""
BRANCH=""

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --repo)
        REPO="${2:-}"
        shift 2
        ;;
      --dir)
        DIR="${2:-}"
        shift 2
        ;;
      --depth)
        DEPTH="${2:-}"
        shift 2
        ;;
      --branch)
        BRANCH="${2:-}"
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

  if [[ -z "$REPO" ]]; then
    echo "Error: --repo is required" >&2
    usage
    exit 1
  fi
}

main() {
  parse_args "$@"
  require_gh

  local cmd=(gh repo clone "$REPO")

  if [[ -n "$DIR" ]]; then
    cmd+=("$DIR")
  fi

  # gh repo clone passes extra args to git clone after --
  local git_args=()
  if [[ -n "$DEPTH" ]]; then
    git_args+=(--depth "$DEPTH")
  fi
  if [[ -n "$BRANCH" ]]; then
    git_args+=(--branch "$BRANCH")
  fi

  if [[ ${#git_args[@]} -gt 0 ]]; then
    cmd+=(-- "${git_args[@]}")
  fi

  echo "Cloning $REPO..."
  "${cmd[@]}"
  echo "Clone completed."
}

main "$@"
