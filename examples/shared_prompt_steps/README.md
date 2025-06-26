# Shared Prompt Steps Example

This example demonstrates how to define and use shared prompt steps across multiple workflows using the `shared` directory and `shared.yml`.

## Structure

```
shared_prompt_steps/
├── shared.yml                      # YAML anchors for referencing shared steps
├── shared/                         # Shared prompt step directories
│   ├── analyze_security/
│   │   └── prompt.md              # Security analysis prompt
│   ├── review_performance/
│   │   └── prompt.md              # Performance review prompt
│   └── validate_inputs/
│       └── prompt.md              # Input validation prompt
└── code_review_workflow/
    └── workflow.yml               # Workflow using shared prompt steps
```

## How Shared Prompt Steps Work

1. **Step Discovery**: When Roast's `StepLoader` looks for a step, it checks:
   - The workflow's directory first
   - Then the `shared` directory (one level up from the workflow)

2. **Using shared.yml**: While not required, `shared.yml` can define YAML anchors for cleaner workflow files:
   ```yaml
   # shared.yml
   analyze_security: &analyze_security analyze_security
   review_performance: &review_performance review_performance
   ```

3. **In workflows**: Reference shared steps either directly or via YAML anchors:
   ```yaml
   steps:
     - analyze_security      # Direct reference
     - *review_performance   # Via YAML anchor
   ```

## Benefits

- **Reusability**: Define common analysis steps once, use across many workflows
- **Consistency**: Ensure all workflows use the same prompts for common tasks
- **Maintainability**: Update prompts in one place, affects all workflows
- **Organization**: Keep workflow-specific steps separate from shared ones

## Running the Example

```bash
# Run the code review workflow that uses shared prompt steps
bin/roast execute examples/shared_prompt_steps/code_review_workflow/workflow.yml --target examples/shared_prompt_steps/sample_code.rb
```

## Creating Your Own Shared Steps

1. Create a directory under `shared/` with your step name
2. Add a `prompt.md` file with the prompt content
3. Optionally, add the step to `shared.yml` as a YAML anchor
4. Reference the step in any workflow within the same parent directory