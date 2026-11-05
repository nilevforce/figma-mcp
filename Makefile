# Everyday commands. The project itself lives in app/.
.DEFAULT_GOAL := help
SHELL := /bin/bash

COMPOSE := docker compose --progress=quiet -f app/compose.yaml

.PHONY: help start stop check-docker

help: ## Show this list
	@echo "What you can do:"
	@echo
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  make %-6s %s\n", $$1, $$2}'
	@echo

# Fail with one plain sentence instead of a wall of Docker errors.
check-docker:
	@docker info >/dev/null 2>&1 || { echo "Docker isn't running. Open Docker Desktop and try again."; exit 1; }

start: check-docker ## Start the service
	@echo "Starting... (the first run takes about a minute)"
	@$(COMPOSE) build
	@$(COMPOSE) up -d --wait --wait-timeout 60
	@echo
	@echo "Done - the service is running."
	@echo "Port 3055 is where the Figma plugin connects."

stop: check-docker ## Stop the service
	@$(COMPOSE) down
	@echo "Service stopped."
