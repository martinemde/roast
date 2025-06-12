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
        API_KEY: "{{ENV['API_KEY']}}"
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

## Running the Examples

### Simple Example (no authentication required)

```bash
# Run the basic MCP example
roast execute examples/mcp/workflow.yml

# Run the multi-tool example
roast execute examples/mcp/multi_mcp_workflow.yml
```

### GitHub Example (requires GitHub token)

```bash
# Set your GitHub token first
export GITHUB_TOKEN="your-github-personal-access-token"

# Run the GitHub workflow
roast execute examples/mcp/github_workflow.yml
```

### Filesystem Example

```bash
# This uses the filesystem MCP server to safely browse /tmp
roast execute examples/mcp/filesystem_demo/workflow.yml
```

## More Examples

### GitHub Integration

```yaml
tools:
  - GitHub:
      command: npx
      args: ["-y", "@modelcontextprotocol/server-github"]
      env:
        GITHUB_PERSONAL_ACCESS_TOKEN: "{{ENV['GITHUB_TOKEN']}}"
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
        DATABASE_URL: "{{ENV['DATABASE_URL']}}"
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

## Installing and Using MCP Servers

MCP servers can be run in different ways:

### Using npx (recommended for testing)

Most official MCP servers can be run directly with npx without installation:

```bash
# These are automatically downloaded and run when used in workflows
npx -y @modelcontextprotocol/server-github
npx -y @modelcontextprotocol/server-filesystem /path/to/allow
npx -y @modelcontextprotocol/server-sqlite /path/to/database.db
```

### Installing globally

For production use, you might want to install servers globally:

```bash
npm install -g @modelcontextprotocol/server-github
npm install -g @modelcontextprotocol/server-filesystem
```

### Available MCP Servers

Popular MCP servers you can use:

- **@modelcontextprotocol/server-filesystem**: Safe filesystem access
- **@modelcontextprotocol/server-github**: GitHub API integration (requires token)
- **@modelcontextprotocol/server-gitlab**: GitLab API integration
- **@modelcontextprotocol/server-google-drive**: Google Drive access
- **@modelcontextprotocol/server-slack**: Slack integration
- **@modelcontextprotocol/server-postgres**: PostgreSQL database access
- **@modelcontextprotocol/server-sqlite**: SQLite database access

For more MCP servers, visit: https://github.com/modelcontextprotocol/servers

## Troubleshooting

### Common Issues

1. **"No such file or directory" error**
   - Make sure `npx` is installed: `which npx`
   - For local commands, ensure they're in your PATH

2. **"Bad credentials" or authentication errors**
   - Check that your environment variables are set correctly
   - Use `{{ENV['VAR_NAME']}}` syntax for interpolation
   - Test with: `echo $GITHUB_TOKEN` to verify it's set

3. **MCP server doesn't start**
   - Try running the command manually first: `npx -y @modelcontextprotocol/server-filesystem /tmp`
   - Check for any npm/node errors

4. **"Step not found" errors**
   - Inline prompts in the workflow use the syntax: `step_name: prompt text`
   - For multi-line prompts use: `step_name: |` followed by indented text
   - For separate prompt files: create `step_name/prompt.md` in the workflow directory

## Security Notes

- Never hardcode credentials - use environment variables
- Use `only` to limit function access when possible
- Be cautious with stdio tools as they execute local processes
- Review MCP server documentation for security best practices
- The filesystem server only allows access to specified directories