# Important Notes for Claude

## Roast Workflow Syntax

### IMPORTANT: No inline configuration for steps!

Roast workflows DO NOT support inline configuration syntax like this:
```yaml
# WRONG - This syntax does NOT exist:
steps:
  - step_name:
      prompt: "some prompt"
      output: variable_name
```

The correct syntax is:
```yaml
# CORRECT - Steps are just names or hash assignments:
steps:
  - step_name
  - variable_name: step_name
  - variable_name: $(command)
```

### Control flow structures

Only control flow structures (if/unless, case/when/else, each, repeat) support nested configuration:

```yaml
steps:
  # Simple step - just the name
  - detect_language
  
  # Variable assignment
  - my_var: detect_language
  
  # Command execution with assignment
  - env_type: $(echo $ENVIRONMENT)
  
  # Control flow - these DO have nested structure
  - if: "{{ condition }}"
    then:
      - step1
      - step2
      
  - case: "{{ expression }}"
    when:
      value1:
        - step1
      value2:
        - step2
    else:
      - step3
```

### Step Configuration

Step configuration (prompts, outputs, etc.) is handled through:
1. File naming conventions (step_name/prompt.md, step_name/output.txt)
2. The workflow configuration file itself (tools, target, etc.)

NOT through inline step configuration in the steps array.

## Remember:
- Steps array contains step names, not step configurations
- Only control flow structures have nested configuration
- Variable assignment uses hash syntax: `var_name: step_name`
- Commands use $() syntax: `var_name: $(command)`