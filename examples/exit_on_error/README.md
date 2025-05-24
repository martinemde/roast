# Exit on Error Example

This example demonstrates how to use the `exit_on_error` configuration option to continue workflow execution even when a command fails.

## Use Case

When running a linter like RuboCop on a file with syntax errors or style violations, the command will exit with a non-zero status. By default, this would halt the workflow. However, we often want to:

1. Capture the linter output (including errors)
2. Analyze what went wrong
3. Apply fixes based on the analysis

## Configuration

The key configuration is in the step configuration section:

```yaml
lint_check:
  exit_on_error: false
```

This tells Roast to:
- Continue workflow execution even if the command fails
- Capture the full output (stdout and stderr)
- Append the exit status to the output

## Output Format

When a command fails with `exit_on_error: false`, the output will look like:

```
lib/example.rb:5:3: C: Style/StringLiterals: Prefer double-quoted strings
  'hello'
  ^^^^^^^
[Exit status: 1]
```

This allows subsequent steps to process both the error output and the exit status.

## Running the Example

```bash
roast execute workflow.yml path/to/file.rb
```

The workflow will:
1. Run RuboCop on the file
2. Continue even if RuboCop finds issues
3. Analyze the linter output
4. Apply fixes based on the analysis