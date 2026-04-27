# 預設顯示幫助
default:
    @just --list

# 顯示目前指令總數
commands-count:
    @echo "Total commands: $(just --summary | tr ' ' '\n' | wc -l)"

# ============================================================
# GitHub Overview
# ============================================================

# 查看我的 GitHub Issues/PR
gh-overview *ARGS:
    @./scripts/gh_overview.sh {{ARGS}}
