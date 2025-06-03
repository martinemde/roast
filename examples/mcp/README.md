# MCP (Model Context Protocol) Tools

This example demonstrates how to use MCP tools in Roast workflows. MCP is an open standard that enables seamless integration between AI applications and external data sources and tools.

## What are MCP Tools?

MCP tools allow your Roast workflows to connect to external services and tools through a standardized protocol. This enables:

- Access to external APIs and services
- Integration with databases and file systems
- Connection to specialized tools and platforms
- Real-time data access during workflow execution

## Configuration

MCP tools are configured in the `tools` section of your workflow YAML file. Roast supports two types of MCP connections:

### 1. SSE (Server-Sent Events) MCP Tools

Connect to HTTP endpoints that implement the MCP protocol:

```yaml
tools:
  - Tool Name:
      url: https://example.com/mcp-endpoint
      env:
        - "Authorization: Bearer {{resource.api_token}}"
      only:
        - allowed_function_1
        - allowed_function_2
```

### 2. Stdio MCP Tools

Connect to local processes that implement the MCP protocol:

```yaml
tools:
  - Tool Name:
      command: docker
      args:
        - run
        - -i
        - --rm
        - ghcr.io/example/mcp-server
      env:
        API_KEY: "{{env.API_KEY}}"
      except:
        - dangerous_function
```

## Parameters

- **`url`** (SSE only): The HTTP(S) endpoint URL for the MCP server
- **`command`** (stdio only): The command to execute
- **`args`** (stdio only): Array of command-line arguments
- **`env`**: Headers (SSE) or environment variables (stdio)
- **`only`**: Whitelist of functions to include
- **`except`**: Blacklist of functions to exclude

## Example Workflow

The `workflow.yml` in this directory shows a simple example using GitMCP to read documentation:

```yaml
name: MCP Tools Example
model: gpt-4o-mini
tools:
  - Roast Docs:
      url: https://gitmcp.io/Shopify/roast/docs

steps:
  - get_doc: Read the Roast docs, and tell me how to use MCP tools.
  - summarize

summarize:
  print_response: true
```

## Running the Example

```bash
roast execute examples/mcp/workflow.yml -o output.md
```

## More Examples

### GitHub Integration

```yaml
tools:
  - GitHub:
      command: npx
      args: ["-y", "@modelcontextprotocol/server-github"]
      env:
        GITHUB_PERSONAL_ACCESS_TOKEN: "{{env.GITHUB_TOKEN}}"
      only:
        - search_repositories
        - get_issue
        - create_issue
```

### Database Access

```yaml
tools:
  - Database:
      command: npx
      args: ["-y", "@modelcontextprotocol/server-postgres"]
      env:
        DATABASE_URL: "{{env.DATABASE_URL}}"
      only:
        - query
        - list_tables
```

### Using Multiple MCP Tools

You can combine MCP tools with traditional Roast tools:

```yaml
tools:
  # Traditional Roast tools
  - Roast::Tools::ReadFile
  - Roast::Tools::WriteFile
  
  # MCP tools
  - External API:
      url: https://api.example.com/mcp
  - Local Tool:
      command: ./my-mcp-server
```

## Available MCP Servers

Popular MCP servers you can use:

- **GitMCP** (https://gitmcp.io): Access any public Git repository
- **@modelcontextprotocol/server-github**: GitHub API integration
- **@modelcontextprotocol/server-slack**: Slack integration
- **@modelcontextprotocol/server-postgres**: PostgreSQL database access
- **@modelcontextprotocol/server-sqlite**: SQLite database access

For more MCP servers, visit: https://github.com/modelcontextprotocol/servers

## Security Notes

- Never hardcode credentials - use environment variables
- Use `only` to limit function access when possible
- Be cautious with stdio tools as they execute local processes
- Review MCP server documentation for security best practices