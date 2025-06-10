# Agent Workflow Example

This example demonstrates the practical differences between regular steps and agent steps in Roast workflows.

## What are Agent Steps?

Agent steps are a special type of step that sends prompts directly to the CodingAgent tool (e.g., Claude Code) without going through the normal LLM translation layer. They're denoted by prefixing the step name with `^`.

## When to Use Each Type

### Regular Steps
Best for tasks that benefit from LLM interpretation:
- Analysis and judgment tasks
- Natural language understanding
- Flexible responses based on context
- Summary and explanation generation

### Agent Steps
Best for tasks requiring precise tool control:
- Exact code refactoring operations
- Multi-file coordinated changes
- Specific tool usage requirements
- Performance-critical operations

## Workflow Structure

This example demonstrates a code refactoring workflow:

1. **identify_code_smells** (Regular Step)
   - Analyzes code to identify issues
   - Uses LLM judgment to prioritize problems
   - Provides contextual explanations

2. **^apply_refactorings** (Agent Step)
   - Executes precise refactoring operations
   - Uses specific tools (Read, MultiEdit) directly
   - Follows exact formatting requirements
   - No interpretation needed - just execution

3. **summarize_improvements** (Regular Step)
   - Reviews all changes made
   - Generates human-friendly summary
   - Provides recommendations

## Running the Workflow

```bash
# Run on all Ruby files in current directory
roast execute examples/agent_workflow/workflow.yml

# Run on specific files
roast execute examples/agent_workflow/workflow.yml app/models/*.rb
```

## Key Differences in Practice

### Regular Step Example
The `identify_code_smells` step benefits from LLM interpretation because:
- It needs to understand "code smells" in context
- It makes subjective judgments about code quality
- It prioritizes issues based on impact

### Agent Step Example
The `^apply_refactorings` step works better as an agent step because:
- It requires specific tool usage (MultiEdit, not Write)
- It needs exact preservation of formatting
- It follows precise refactoring patterns
- No interpretation is needed - just execution

## Benefits Demonstrated

1. **Complementary Strengths**: Regular steps handle analysis and planning, agent steps handle precise execution
2. **Better Performance**: Agent steps skip the LLM layer for well-defined tasks
3. **Predictable Results**: Agent steps execute exactly as specified
4. **Tool Control**: Agent steps can enforce specific tool usage patterns