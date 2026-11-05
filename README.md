# Talk to Figma MCP

This project implements a Model Context Protocol (MCP) integration between AI agents (Cursor, Claude Code, OpenCode) and Figma, allowing AI agent to communicate with Figma for reading designs and modifying them programmatically.

https://github.com/user-attachments/assets/129a14d2-ed73-470f-9a4c-2240b2a4885c

## Project Structure

All project code lives in `app/`, so container and Make commands run from the repo root and Bun commands from `app/`.

- `app/src/talk_to_figma_mcp/` - TypeScript MCP server for Figma integration
- `app/src/cursor_mcp_plugin/` - Figma plugin for communicating with Cursor
- `app/src/socket.ts` - WebSocket server that facilitates communication between the MCP server and Figma plugin
- `app/compose.yaml` - Docker Compose services (`relay` and `mcp`)

## Quick start (Docker Compose)

You only need Docker - Bun is not required, everything runs in a container.

1. Start everything from the repo root:

```bash
make mcp
```

This builds the image, starts the relay on port **3055** (the bridge between Figma and your AI agent) and runs the MCP server on stdio. You normally do not run it by hand - your AI client does, using exactly this command - but it is the same thing either way. `make stop` frees the port when you are done.

2. Install the Figma plugin from the [Figma community page](https://www.figma.com/community/plugin/1485687494525374295/cursor-talk-to-figma-mcp-plugin) or [install it locally](#figma-plugin).

3. Point your MCP client at the container - see [Connect your MCP client](#connect-your-mcp-client).

4. In Figma, run the **Cursor Talk To Figma MCP Plugin**, connect it to port `3055`, and ask your agent to `join_channel` with the same channel name. Then describe the design change you want.

If your agent reports `Not connected to Figma`, it started before the plugin joined the channel - run `join_channel` again.

## Quick Video Tutorial

[Video Link](https://www.linkedin.com/posts/sonnylazuardi_just-wanted-to-share-my-latest-experiment-activity-7307821553654657024-yrh8)

## Design Automation Example

**Bulk text content replacement**

Thanks to [@dusskapark](https://github.com/dusskapark) for contributing the bulk text replacement feature. Here is the [demo video](https://www.youtube.com/watch?v=j05gGT3xfCs).

**Instance Override Propagation**
Another contribution from [@dusskapark](https://github.com/dusskapark)
Propagate component instance overrides from a source instance to multiple target instances with a single command. This feature dramatically reduces repetitive design work when working with component instances that need similar customizations. Check out our [demo video](https://youtu.be/uvuT8LByroI).

## Connect your MCP client

All clients start the server the same way - `make mcp`, which runs the container that speaks MCP over stdio:

```bash
make --no-print-directory -C /path-to-repo mcp
```

Two details are load-bearing. `--no-print-directory` is not optional: without it make writes `Entering directory ...` to stdout, which is exactly the channel the protocol runs on, and the client breaks. The relay comes up on its own the first time - the server waits up to 15 seconds for it before failing a command.

### Cursor

Add to `~/.cursor/mcp.json`, or to `.cursor/mcp.json` in a project:

```json
{
  "mcpServers": {
    "TalkToFigma": {
      "command": "make",
      "args": ["--no-print-directory", "-C", "/path-to-repo", "mcp"]
    }
  }
}
```

### Claude Code

```bash
claude mcp add TalkToFigma -- make --no-print-directory -C /path-to-repo mcp
```

### OpenCode

Let OpenCode write the config for you:

```bash
opencode mcp add TalkToFigma -- make --no-print-directory -C /path-to-repo mcp
```

Or add it by hand, in `opencode.json` at the project root or in `~/.config/opencode/opencode.json`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "servers": {
      "TalkToFigma": {
        "type": "local",
        "command": ["make", "--no-print-directory", "-C", "/path-to-repo", "mcp"],
        "timeout": { "execution": 60000 }
      }
    }
  }
}
```

Use OpenCode 2.x - the older `mcp.<name>` shape is ignored by it, not just deprecated, so the server silently never appears. `timeout.execution` matters too: the default is 5 seconds per request, and `get_document_info` or `scan_text_nodes` on a large file takes longer.

## Figma Plugin

Either install it from the [Figma community page](https://www.figma.com/community/plugin/1485687494525374295/cursor-talk-to-figma-mcp-plugin), or link the local build:

1. In Figma, go to Plugins > Development > New Plugin
2. Choose "Link existing plugin"
3. Select the `app/src/cursor_mcp_plugin/manifest.json` file
4. The plugin should now be available in your Figma development plugins

## Run without Docker

With Bun installed, the relay and the server can run straight from `app/`:

```bash
cd app
bun install
bun socket     # relay on port 3055
```

Then point your MCP client at the published package instead of the container:

```bash
# Claude Code
claude mcp add TalkToFigma -- bunx cursor-talk-to-figma-mcp@latest

# OpenCode
opencode mcp add TalkToFigma -- bunx cursor-talk-to-figma-mcp@latest
```

For Cursor, set `"command": "bunx"` and `"args": ["cursor-talk-to-figma-mcp@latest"]`. Running `bun setup` from `app/` writes exactly that config to `.cursor/mcp.json` and `.mcp.json` at the repo root.

## Windows + WSL Guide

1. Install bun via powershell

```bash
powershell -c "irm bun.sh/install.ps1|iex"
```

2. Uncomment the hostname `0.0.0.0` in `app/src/socket.ts`

```typescript
// uncomment this to allow connections in windows wsl
hostname: "0.0.0.0",
```

3. Start the websocket

```bash
cd app && bun socket
```

## Usage

1. Start the relay (`make mcp`, which brings it up, or `bun socket` from `app/`)
2. Connect your MCP client to the server ([Cursor](#cursor), [Claude Code](#claude-code), [OpenCode](#opencode))
3. Open Figma and run the Cursor Talk To Figma MCP Plugin
4. Connect the plugin to the WebSocket server by joining a channel using `join_channel`
5. Use your AI agent to communicate with Figma using the MCP tools

## Local Development Setup

To run the MCP server from a local checkout instead of the container or the published package, point your client at `server.ts`:

```json
{
  "mcpServers": {
    "TalkToFigma": {
      "command": "bun",
      "args": ["/path-to-repo/app/src/talk_to_figma_mcp/server.ts"]
    }
  }
}
```

For a quick run in the foreground, `make mcp` does the same thing from the image.

## MCP Tools

The MCP server provides the following tools for interacting with Figma:

### Document & Selection

- `get_document_info` - Get information about the current Figma document
- `get_selection` - Get information about the current selection
- `read_my_design` - Get detailed node information about the current selection without parameters
- `get_node_info` - Get detailed information about a specific node
- `get_nodes_info` - Get detailed information about multiple nodes by providing an array of node IDs
- `set_focus` - Set focus on a specific node by selecting it and scrolling viewport to it
- `set_selections` - Set selection to multiple nodes and scroll viewport to show them

### Annotations

- `get_annotations` - Get all annotations in the current document or specific node
- `set_annotation` - Create or update an annotation with markdown support
- `set_multiple_annotations` - Batch create/update multiple annotations efficiently
- `scan_nodes_by_types` - Scan for nodes with specific types (useful for finding annotation targets)

### Prototyping & Connections

- `get_reactions` - Get all prototype reactions from nodes with visual highlight animation
- `set_default_connector` - Set a copied FigJam connector as the default connector style for creating connections (must be set before creating connections)
- `create_connections` - Create FigJam connector lines between nodes, based on prototype flows or custom mapping

### Creating Elements

- `create_rectangle` - Create a new rectangle with position, size, and optional name
- `create_frame` - Create a new frame with position, size, and optional name
- `create_section` - Create a section to group related content on the canvas
- `create_text` - Create a new text node with customizable font properties

### Modifying text content

- `scan_text_nodes` - Scan text nodes with intelligent chunking for large designs
- `set_text_content` - Set the text content of a single text node
- `set_multiple_text_contents` - Batch update multiple text nodes efficiently

### Auto Layout & Spacing

- `set_layout_mode` - Set the layout mode and wrap behavior of a frame (NONE, HORIZONTAL, VERTICAL)
- `set_padding` - Set padding values for an auto-layout frame (top, right, bottom, left)
- `set_axis_align` - Set primary and counter axis alignment for auto-layout frames
- `set_layout_sizing` - Set horizontal and vertical sizing modes for auto-layout frames (FIXED, HUG, FILL)
- `set_item_spacing` - Set distance between children in an auto-layout frame

### Styling

- `set_fill_color` - Set the fill color of a node (RGBA)
- `set_stroke_color` - Set the stroke color and weight of a node
- `set_corner_radius` - Set the corner radius of a node with optional per-corner control
- `set_image_fill` - Fill a node with an image from a local file path, URL, or base64 data (FILL, FIT, CROP, or TILE)

### Layout & Organization

- `move_node` - Move a node to a new position
- `resize_node` - Resize a node with new dimensions
- `delete_node` - Delete a node
- `delete_multiple_nodes` - Delete multiple nodes at once efficiently
- `clone_node` - Create a copy of an existing node with optional position offset
- `rename_node` - Rename a node
- `set_parent` - Move a node into a new parent (section, frame or group), preserving its absolute position by default

### Components & Styles

- `get_styles` - Get information about local styles
- `get_local_components` - Get information about local components
- `create_component_instance` - Create an instance of a component
- `get_instance_overrides` - Extract override properties from a selected component instance
- `set_instance_overrides` - Apply extracted overrides to target instances

### Export & Advanced

- `export_node_as_image` - Export a node as an image (PNG, JPG, SVG, or PDF) - limited support on image currently returning base64 as text

### Connection Management

- `join_channel` - Join a specific channel to communicate with Figma

### MCP Prompts

The MCP server includes several helper prompts to guide you through complex design tasks:

- `design_strategy` - Best practices for working with Figma designs
- `read_design_strategy` - Best practices for reading Figma designs
- `text_replacement_strategy` - Systematic approach for replacing text in Figma designs
- `annotation_conversion_strategy` - Strategy for converting manual annotations to Figma's native annotations
- `swap_overrides_instances` - Strategy for transferring overrides between component instances in Figma
- `reaction_to_connector_strategy` - Strategy for converting Figma prototype reactions to connector lines using the output of 'get_reactions', and guiding the use 'create_connections' in sequence

## Development

### Building the Figma Plugin

1. Navigate to the Figma plugin directory:

   ```
   cd app/src/cursor_mcp_plugin
   ```

2. Edit code.js and ui.html

## Best Practices

When working with the Figma MCP:

1. Always join a channel before sending commands
2. Get document overview using `get_document_info` first
3. Check current selection with `get_selection` before modifications
4. Use appropriate creation tools based on needs:
   - `create_frame` for containers
   - `create_rectangle` for basic shapes
   - `create_text` for text elements
5. Verify changes using `get_node_info`
6. Use component instances when possible for consistency
7. Handle errors appropriately as all commands can throw exceptions
8. For large designs:
   - Use chunking parameters in `scan_text_nodes`
   - Monitor progress through WebSocket updates
   - Implement appropriate error handling
9. For text operations:
   - Use batch operations when possible
   - Consider structural relationships
   - Verify changes with targeted exports
10. For converting legacy annotations:
    - Scan text nodes to identify numbered markers and descriptions
    - Use `scan_nodes_by_types` to find UI elements that annotations refer to
    - Match markers with their target elements using path, name, or proximity
    - Categorize annotations appropriately with `get_annotations`
    - Create native annotations with `set_multiple_annotations` in batches
    - Verify all annotations are properly linked to their targets
    - Delete legacy annotation nodes after successful conversion
11. Visualize prototype noodles as FigJam connectors:

- Use `get_reactions` to extract prototype flows,
- set a default connector with `set_default_connector`,
- and generate connector lines with `create_connections` for clear visual flow mapping.

## License

MIT
