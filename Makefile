# Everyday commands. The project itself lives in app/.
.DEFAULT_GOAL := help
SHELL := /bin/bash

COMPOSE := docker compose --progress=quiet -f app/compose.yaml

# Containers left behind by a client that died before its server could exit.
STALE := docker ps -aq --filter "label=com.docker.compose.service=mcp"

.PHONY: help mcp stop check-docker

help: ## Show this list
	@echo "What you can do:"
	@echo
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  make %-6s %s\n", $$1, $$2}'
	@echo

# Fail with one plain sentence instead of a wall of Docker errors.
check-docker:
	@docker info >/dev/null 2>&1 || { echo "Docker isn't running. Open Docker Desktop and try again."; exit 1; }

# The MCP server - what an AI client starts and talks to over stdio. Not a daemon: it exits
# with its client, and the relay it needs comes up as a dependency of the compose service.
# Everything printed here goes to stderr, because stdout is the protocol channel.
mcp: check-docker ## Start the app (relay + MCP server)
	@echo "Starting... the relay comes up too. Ctrl-C stops it." >&2
	@$(COMPOSE) build
	@$(COMPOSE) up -d --wait relay
	@$(COMPOSE) run --rm -i mcp

stop: check-docker ## Stop everything and free the port
	@$(COMPOSE) down --remove-orphans >/dev/null 2>&1 || true
	@ids=$$($(STALE)); if [ -n "$$ids" ]; then docker rm -f $$ids >/dev/null; fi
	@echo "Stopped." >&2
