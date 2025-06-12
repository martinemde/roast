# User Input Example

This example demonstrates how to use the `input` step type in Roast workflows to collect information from users during workflow execution.

## Overview

The `input` step type allows workflows to:
- Collect text input from users
- Ask yes/no questions (boolean)
- Present multiple choice options
- Securely collect passwords (hidden input)
- Store collected values in workflow state for later use

## Running the Example

```bash
# Run the interactive deployment workflow
roast execute examples/user_input/workflow.yml

# Run a simple survey workflow
roast execute examples/user_input/survey_workflow.yml
```

## Input Step Configuration

### Basic Text Input
```yaml
- input:
    prompt: "Enter your name:"
    name: user_name
```

### Boolean (Yes/No) Input
```yaml
- input:
    prompt: "Do you want to continue?"
    type: boolean
    default: true
    name: should_continue
```

### Choice Selection
```yaml
- input:
    prompt: "Select environment:"
    type: choice
    options:
      - development
      - staging
      - production
    name: environment
```

### Password Input
```yaml
- input:
    prompt: "Enter password:"
    type: password
    required: true
    name: user_password
```

## Configuration Options

- `prompt` (required): The question or message to display to the user
- `name` (optional): Variable name to store the input value in workflow state
- `type` (optional): Type of input - `text` (default), `boolean`, `choice`, or `password`
- `required` (optional): Whether the input is required (default: false)
- `default` (optional): Default value if user presses enter without input
- `timeout` (optional): Timeout in seconds for user input
- `options` (required for choice type): Array of options for choice selection

## Accessing Input Values

Input values stored with a `name` can be accessed in subsequent steps using interpolation:

```yaml
- input:
    prompt: "Enter project name:"
    name: project_name

- prompt: "Creating project: #{state.project_name}"
```

## Non-TTY Environments

When running in non-TTY environments (e.g., CI/CD pipelines), input steps will:
- Use default values if provided
- Fail if required inputs have no default
- Skip optional inputs without defaults