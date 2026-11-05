#!/bin/bash
set -e

# Project code lives in app/; agent-facing config lives at the repo root.
APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REPO_ROOT="$(cd "$APP_DIR/.." && pwd)"

MCP_CONFIG='{
  "mcpServers": {
    "TalkToFigma": {
      "command": "bunx",
      "args": [
        "cursor-talk-to-figma-mcp@latest"
      ]
    }
  }
}'

cd "$APP_DIR"
bun install

# Cursor: write .cursor/mcp.json at the repo root
mkdir -p "$REPO_ROOT/.cursor"
echo "$MCP_CONFIG" > "$REPO_ROOT/.cursor/mcp.json"
echo "✓ Cursor MCP config written to .cursor/mcp.json"

# Claude Code: write .mcp.json at the repo root
echo "$MCP_CONFIG" > "$REPO_ROOT/.mcp.json"
echo "✓ Claude Code MCP config written to .mcp.json"
