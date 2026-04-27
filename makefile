SHELL := /bin/bash

.DEFAULT_GOAL := help

.PHONY: help commands-count fmt fmt-sh fmt-md gh-overview
help: ## 顯示所有可用指令
	@awk 'BEGIN {FS = ":.*## "; print "Available commands:"} /^[a-zA-Z0-9_.-]+:.*## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

commands-count: ## 顯示目前指令總數
	@count=$$(awk 'BEGIN {c=0} /^[a-zA-Z0-9_.-]+:.*## / {c++} END {print c}' $(MAKEFILE_LIST)); echo "Total commands: $$count"

# ============================================================
# GitHub Overview
# ============================================================

gh-overview: ## 查看我的 GitHub Issues/PR
	@./scripts/gh_overview.sh $(ARGS)
