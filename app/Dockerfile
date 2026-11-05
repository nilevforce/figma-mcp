# Build context is app/ (this Dockerfile lives there): docker build -t cursor-talk-to-figma-mcp app/
FROM oven/bun:latest

# Set the working directory in the container
WORKDIR /app

# Copy the project files into the container at /app
COPY package*.json ./
RUN bun install

COPY . .

# Expose the port on which the API will listen
EXPOSE 3055

# Run the server when the container launches
CMD ["bun", "src/talk_to_figma_mcp/server.ts"]
