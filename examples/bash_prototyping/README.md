# Bash Tool Prototyping Example

This example demonstrates the unrestricted `Roast::Tools::Bash` tool, designed for prototyping and development scenarios where you need full command-line access.

## ⚠️ Important Warning

The Bash tool provides **unrestricted access** to execute any system command. This is intentionally designed for:
- Rapid prototyping workflows
- Development environments
- Scenarios where you trust the AI with full system access
- Quick experiments without command restrictions

**DO NOT USE** this tool in:
- Production environments
- Untrusted contexts
- Public-facing workflows
- Any scenario where command restrictions are needed for security

## When to Use Bash vs Cmd

### Use `Roast::Tools::Cmd` when:
- You want explicit control over allowed commands
- Security is a concern
- You're building production workflows
- You want to limit the AI to specific, safe commands

### Use `Roast::Tools::Bash` when:
- You're prototyping and need flexibility
- You're in a trusted development environment
- You need commands not available in Cmd's allowed list
- You explicitly want to give the AI full command access

## Example Usage

The included workflow demonstrates:
1. System exploration with unrestricted commands
2. Package management operations
3. Complex shell operations with pipes and redirects
4. File system operations beyond basic commands

## Running the Example

```bash
bin/roast execute examples/bash_prototyping/workflow.yml
```

## Security Considerations

- The Bash tool logs warnings by default to remind you of unrestricted access
- Set `ROAST_BASH_WARNINGS=false` to suppress warnings if desired
- Always review generated commands before running in sensitive environments
- Consider using `Roast::Tools::Cmd` with custom allowed_commands for production use