# Code Quality Analysis Workflow

This example demonstrates the use of Roast's iteration features to analyze and improve code quality across a codebase.

## What it does

1. Collects Ruby files from the codebase for analysis
2. Analyzes each file for complexity, code smells, and potential improvements
3. Generates recommendations for each file
4. Prioritizes the identified issues by impact and difficulty
5. Automatically implements fixes for the highest-priority issues
6. Verifies each fix before moving to the next one
7. Continues until either 5 fixes have been applied or all issues are addressed
8. Generates a summary report of changes made

## Iteration Features Demonstrated

### Collection Iteration with `each`

The workflow uses the `each` construct to iterate through Ruby files:

```yaml
- each: "output['get_files_to_analyze'].split('\n')"
  as: "current_file"
  steps:
    - read_file
    - analyze_complexity
    - generate_recommendations
```

This makes the current file available as `current_file` in each step, allowing the analysis steps to process each file individually.

### Conditional Repetition with `repeat`

The workflow uses the `repeat` construct to iteratively fix issues until a condition is met:

```yaml
- repeat:
    steps:
      - select_next_issue
      - implement_fix
      - verify_fix
      - update_fix_count
    until: "output['update_fix_count']['fixes_applied'] >= 5 || output['select_next_issue']['no_issues_left'] == true"
    max_iterations: 10
```

This continues applying fixes until either:
- 5 fixes have been successfully applied
- No more issues remain to be fixed
- The maximum of 10 iterations is reached (safety limit)

## Running the Example

To run this workflow:

```bash
roast run examples/iteration/workflow.yml --target=/path/to/your/project
```

The workflow will analyze the Ruby files in your project, suggest improvements, and apply the highest-priority fixes.

## Customizing

- Adjust the file selection criteria in `get_files_to_analyze`
- Modify the analysis criteria in `analyze_complexity`
- Change the fix limit in the `until` condition
- Set a different `max_iterations` value to control the maximum number of fixes