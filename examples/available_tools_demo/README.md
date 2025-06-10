# Available Tools Demo

This example demonstrates the `available_tools` feature in Roast, which allows you to restrict which tools are available to specific steps in your workflow.

## Overview

The workflow consists of three steps, each with different tool access:

1. **explore_directory**: Can only use `pwd` and `ls` commands
2. **analyze_files**: Can only use `grep` and `read_file` tools
3. **write_summary**: Can only use `write_file` and `echo` tools

## Key Features Demonstrated

### Security Through Least Privilege
Each step only has access to the tools it needs. For example, the exploration step cannot write files, and the summary step cannot read files or explore directories.

### Tool Name Convention
- For built-in tools: Use snake_case names (e.g., `read_file` for `Roast::Tools::ReadFile`)
- For Cmd tool: Use the specific command names (e.g., `pwd`, `ls`)

### Configuration Structure
```yaml
step_name:
  available_tools:
    - tool1
    - tool2
```

## Running the Example

```bash
roast examples/available_tools_demo/workflow.yml
```

## What Happens

1. The first step explores the current directory using only `pwd` and `ls`
2. The second step searches for Ruby files and reads one using only `grep` and `read_file`
3. The final step creates a summary file using only `write_file` and `echo`

Each step is restricted to its specified tools, demonstrating how you can create secure, focused workflows where each step has exactly the capabilities it needs.