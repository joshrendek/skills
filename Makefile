# Makefile for joshrendek/skills
# All real logic lives in scripts/ so it is reusable and individually testable.

SHELL := /bin/sh
SCRIPTS := scripts

.DEFAULT_GOAL := help
.PHONY: help validate install install-test check move uninstall list

help: ## Show this help
	@awk 'BEGIN { FS = ":.*##" } /^[a-zA-Z_-]+:.*##/ { printf "  \033[36m%-13s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

validate: ## Structurally validate every skill (frontmatter, name == dir)
	@sh $(SCRIPTS)/validate.sh

install: ## Symlink all skills into ~/.claude/skills and ~/.codex/skills
	@sh $(SCRIPTS)/install.sh

install-test: ## Verify installation works against a throwaway HOME (no side effects)
	@sh $(SCRIPTS)/install-test.sh

check: validate install-test ## CI entrypoint: validate + install-test

move: ## Adopt an existing skill into the repo and symlink back (make move SKILL=<name>)
	@sh $(SCRIPTS)/move.sh "$(SKILL)"

uninstall: ## Remove symlinks that point into this repo
	@sh $(SCRIPTS)/uninstall.sh

list: ## List published skills
	@REPO_ROOT="$(CURDIR)" sh -c '. $(SCRIPTS)/lib.sh; list_skills'
