# Bash Tool Examples

This directory contains example workflows demonstrating the Bash tool, which provides unrestricted command execution for prototyping scenarios.

## ⚠️ Security Warning

The Bash tool executes commands without any restrictions. Only use it in:
- Development environments
- Trusted contexts
- Prototyping scenarios where you explicitly want unrestricted access

**Never use the Bash tool in production workflows or with untrusted input!**

## Examples

### 1. System Analysis Workflow (`system_analysis.yml`)

Demonstrates using Bash for system inspection and analysis tasks that would be restricted by the Cmd tool.

### 2. API Testing Workflow (`api_testing.yml`)

Shows how to use Bash for making API calls with curl and processing responses with jq.

### 3. DevOps Automation (`devops_workflow.yml`)

Example of using Bash for DevOps tasks like container management and log analysis.

## Disabling Warnings

By default, the Bash tool logs warnings about unrestricted execution. To disable these warnings:

```bash
export ROAST_BASH_WARNINGS=false
roast execute workflow.yml
```

## Best Practices

1. **Use Cmd tool when possible**: If your commands fit within Cmd's allowed list, use it instead
2. **Validate inputs**: Always validate any user input before passing to Bash
3. **Limit scope**: Use the most restrictive tool that meets your needs
4. **Document risks**: Clearly document when and why Bash tool is necessary
5. **Environment isolation**: Run Bash workflows in isolated environments when possible

## Comparison with Cmd Tool

| Feature | Cmd Tool | Bash Tool |
|---------|----------|-----------|
| Command restrictions | Yes (configurable) | No |
| Default allowed commands | pwd, find, ls, rake, ruby, dev, mkdir | All commands |
| Security warnings | No | Yes (can be disabled) |
| Recommended for production | Yes | No |
| Use case | General automation | Prototyping & development |