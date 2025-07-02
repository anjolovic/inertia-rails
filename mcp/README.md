# Inertia Rails MCP Server

This MCP (Model Context Protocol) server provides AI assistants like Claude with comprehensive access to Inertia-rails documentation, methods, and examples.

## Features

The Inertia Rails MCP server exposes the following tools:

- **documentation**: Search and retrieve Inertia-rails documentation
- **method_lookup**: Look up method signatures and usage examples
- **changelog**: Search version history and changes
- **example**: Get code examples for common use cases

And these resources:

- **api_reference**: Complete API reference
- **configuration**: Configuration guide

## Installation

### 1. Using npm (Recommended for Claude Code)

Install the published npm package:

```bash
# Install globally
npm install -g @anjolovic/inertia-rails-mcp

# Or use directly with npx
npx @anjolovic/inertia-rails-mcp
```

Then add to your Claude Code configuration (`~/Library/Application Support/Code/User/claude.json` on macOS):

```json
{
  "mcpServers": {
    "inertia-rails": {
      "command": "npx",
      "args": ["-y", "@anjolovic/inertia-rails-mcp@latest"]
    }
  }
}
```

### 2. Using Claude Desktop

For Claude Desktop, you can either use the npm package:

```json
{
  "mcpServers": {
    "inertia-rails": {
      "command": "npx",
      "args": ["@anjolovic/inertia-rails-mcp"]
    }
  }
}
```

Or run directly from source:

```json
{
  "mcpServers": {
    "inertia-rails": {
      "command": "ruby",
      "args": ["/path/to/inertia-rails/mcp/server.rb"],
      "env": {
        "INERTIA_RAILS_PATH": "/path/to/inertia-rails"
      }
    }
  }
}
```

### 3. Using Claude CLI

The `.mcp.json` file in the project root is already configured. Just run Claude from the inertia-rails directory:

```bash
cd /path/to/inertia-rails
claude --mcp-config .mcp.json
```

**Note:** The npm package requires Ruby to be installed on your system.

## Usage Examples

Once connected, Claude can help with Inertia-rails development:

### Search Documentation
```
@inertia-rails Can you show me documentation about lazy loading?
```

### Look Up Methods
```
@inertia-rails What's the signature for the inertia_share method?
```

### Get Examples
```
@inertia-rails Show me an example of pagination with Inertia
```

### Check Changelog
```
@inertia-rails What's new in version 3.0?
```

## Available Tools

### inertia_rails_documentation
Search through Inertia-rails documentation.

**Parameters:**
- `query` (required): Search term
- `category` (optional): "guide", "cookbook", "api", or "all"

### inertia_rails_method_lookup
Get detailed information about Inertia-rails methods.

**Parameters:**
- `method_name` (required): Name of the method
- `include_source` (optional): Include source location

### inertia_rails_changelog
Search version history and changes.

**Parameters:**
- `version` (optional): Specific version or "latest"
- `search` (optional): Search term

### inertia_rails_example
Get code examples for common patterns.

**Parameters:**
- `topic` (required): One of:
  - basic_setup
  - shared_data
  - authentication
  - file_upload
  - pagination
  - validation
  - ssr
  - lazy_loading
  - typescript
  - testing

## Development

To modify or extend the MCP server:

1. Edit tool implementations in `mcp/tools/`
2. Add new resources in `mcp/resources/`
3. Update the server configuration in `mcp/server.rb`

### Adding a New Tool

Create a new file in `mcp/tools/`:

```ruby
module InertiaRailsMCP
  module Tools
    class MyNewTool
      def description
        'Description of what this tool does'
      end

      def input_schema
        {
          type: 'object',
          properties: {
            param1: { type: 'string', description: 'Parameter description' }
          },
          required: ['param1']
        }
      end

      def call(arguments)
        # Tool implementation
        "Result of tool execution"
      end
    end
  end
end
```

Then register it in `server.rb`:

```ruby
@tools = {
  'my_new_tool' => Tools::MyNewTool.new,
  # ... other tools
}
```

## Testing

To test the MCP server manually:

```bash
# Run the server directly
ruby mcp/server.rb

# Send a test request (in another terminal)
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | ruby mcp/server.rb
```

## Troubleshooting

### Server Not Responding
- Check Ruby is in PATH
- Verify file permissions
- Check for syntax errors: `ruby -c mcp/server.rb`

### Documentation Not Found
- Ensure the `docs/` directory exists
- Check file paths are correct
- Verify working directory

### Method Lookup Fails
- The gem must be installed or in the load path
- Check for require errors in the server log