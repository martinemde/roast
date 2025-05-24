# Dot Notation Access Example

This example demonstrates the new dot notation access feature for workflow outputs.

## Usage

With the new dot notation feature, you can access output values using Ruby's method syntax instead of hash syntax:

### Before (hash syntax):
```yaml
until: "output[:update_fix_count][:fixes_applied] >= 5 || output[:select_next_issue][:no_issues_left] == true"
```

### After (dot notation):
```yaml
until: "output.update_fix_count.fixes_applied >= 5 || output.select_next_issue.no_issues_left?"
```

### Even cleaner (omitting output prefix):
```yaml
until: "update_fix_count.fixes_applied >= 5 || select_next_issue.no_issues_left?"
```

## Features

1. **Nested access**: `output.step_name.nested.value`
2. **Boolean predicates**: `output.step_name.is_complete?` returns false for nil/false values
3. **Direct access**: Omit the `output.` prefix for cleaner syntax
4. **Backward compatible**: Hash syntax still works (`output[:step_name][:value]`)

## Example Workflow

See `workflow.yml` for a complete example that demonstrates:
- Setting values in output
- Using dot notation in conditions
- Boolean predicate methods
- Nested value access