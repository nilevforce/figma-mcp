# Everyday commands. The project itself lives in app/.
.DEFAULT_GOAL := help
SHELL := /bin/bash

COMPOSE := docker compose --progress=quiet -f app/compose.yaml
IMAGE   := figma-mcp:local
PROJECT := figma-mcp

# MCP servers left behind by a client that was killed before its server could exit. `--rm`
# handles the normal and the hard-kill cases; this is the safety net for a client that died
# while compose was still starting the container. Scoped to this project on purpose: filtering
# on the service label alone would match every project that happens to have a service "mcp".
LEFTOVER_MCP := docker ps -aq --filter "label=com.docker.compose.project=$(PROJECT)" --filter "label=com.docker.compose.service=mcp" --filter "status=exited" --filter "status=created"
PROJECT_CONTAINERS := docker ps -aq --filter "label=com.docker.compose.project=$(PROJECT)"

.PHONY: help build mcp stop check-docker

help: ## Show this list
	@echo "What you can do:"
	@echo
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  make %-6s %s\n", $$1, $$2}'
	@echo

# Fail with one plain sentence instead of a wall of Docker errors.
check-docker:
	@docker info >/dev/null 2>&1 || { echo "Docker isn't running. Open Docker Desktop and try again." >&2; exit 1; }

build: check-docker ## Rebuild the image from app/
	@$(COMPOSE) build

# The MCP server - what an AI client starts and talks to over stdio. Not a daemon: it exits
# with its client. The relay it needs comes up as a compose dependency of the service
# (`docker compose run` starts it and waits for its healthcheck) and is left running on
# purpose: the Figma plugin does not reconnect on its own, so a relay that died with every
# client would disconnect Figma on each restart of an MCP server. `make stop` shuts it down.
# Everything printed here goes to stderr, because stdout is the protocol channel.
mcp: check-docker ## Start the app (relay + MCP server)
	@docker image inspect $(IMAGE) >/dev/null 2>&1 || $(COMPOSE) build
	@ids=$$($(LEFTOVER_MCP)); \
		if [ -n "$$ids" ]; then echo "Removing leftover MCP containers: $$ids" >&2; docker rm -f $$ids >/dev/null; fi
	@echo 'Starting the MCP server over stdio. Ctrl-C stops the server; the relay keeps running so Figma stays connected - `make stop` shuts it down.' >&2
	@$(COMPOSE) run --rm -i mcp; status=$$?; \
		[ $$status -eq 130 ] && exit 0; \
		exit $$status

stop: check-docker ## Stop everything and free the port
	@echo "Removing the relay container, its network, and any leftover MCP containers." >&2
	@$(COMPOSE) down --remove-orphans >/dev/null 2>&1 || true
	@ids=$$($(PROJECT_CONTAINERS)); \
		if [ -n "$$ids" ]; then echo "Removing leftover containers: $$ids" >&2; docker rm -f $$ids >/dev/null; fi
	@echo "Stopped." >&2
