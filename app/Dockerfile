# syntax=docker/dockerfile:1

# Build context is app/ (this Dockerfile lives there): docker build -t figma-mcp:local app/
# Pinned on purpose - the compose stack is verified against this Bun version, and `latest`
# would silently swap the runtime under us.
FROM oven/bun:1.4.4 AS runtime

LABEL org.opencontainers.image.title="Talk to Figma MCP" \
      org.opencontainers.image.description="MCP server and WebSocket relay between Figma and AI agents" \
      org.opencontainers.image.source="https://github.com/nilevforce/figma-mcp"

WORKDIR /app

# Dependencies before source, so editing a .ts file does not re-install everything. Dev
# dependencies (tsup, typescript) are not needed at runtime: Bun executes the TypeScript
# sources directly, and the compose services never build dist/.
COPY package.json bun.lock ./
RUN bun install --frozen-lockfile --production

COPY . .

ENV NODE_ENV=production

# Documented, not functional: the relay's published port is what callers dial.
EXPOSE 3055

# The base image already ships an unprivileged `bun` user (uid 1000). Nothing here writes to
# disk, so the container can run with a read-only root filesystem - see app/compose.yaml.
USER bun

CMD ["bun", "src/talk_to_figma_mcp/server.ts"]
