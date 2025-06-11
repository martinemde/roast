# Validate Changes

Validate the changes made to <%= file %>:

1. **Run the updated tests** and ensure they all pass
2. **Check coverage metrics** to verify improvements
3. **Measure execution time** to confirm performance gains
4. **Verify no regressions** were introduced
5. **Ensure code style** follows project conventions

Store the validation results in the workflow state:
```json
{
  "file": "<%= file %>",
  "tests_passed": true,
  "coverage_before": 0.0,
  "coverage_after": 0.0,
  "execution_time_before": 0.0,
  "execution_time_after": 0.0,
  "issues_found": []
}
```

If any issues are found, provide recommendations for fixing them.