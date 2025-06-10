# Agent Workflow Example

This example demonstrates the use of agent steps in Roast workflows.

## What are Agent Steps?

Agent steps are a special type of step that sends prompts directly to the CodingAgent tool (e.g., Claude Code) without going through the normal LLM translation layer. This is useful when you want to give precise instructions to a coding agent.

## How to Use

Agent steps are denoted by prefixing the step name with `^`:

```yaml
steps:
  - regular_step      # Normal step - goes through LLM
  - ^agent_step       # Agent step - direct to CodingAgent
```

## Workflow Structure

This example workflow has three steps:

1. **analyze_code** - A regular step that analyzes code for issues
2. **^fix_issues** - An agent step that fixes the identified issues directly
3. **verify_fixes** - A regular step that verifies the fixes

## Running the Workflow

```bash
roast execute examples/agent_workflow/workflow.yml your_code.rb
```

## Benefits of Agent Steps

- **Direct control**: Your prompt goes directly to the coding agent without interpretation
- **Precision**: Useful for complex coding tasks where exact instructions matter
- **Efficiency**: Skips the LLM translation layer when not needed