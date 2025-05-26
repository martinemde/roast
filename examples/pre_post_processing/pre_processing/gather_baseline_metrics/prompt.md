# Gather Baseline Metrics

Analyze the current test suite and gather baseline metrics for comparison. Please provide:

1. Total number of test files to be processed
2. Current overall test coverage percentage
3. Average test execution time across all files
4. Number of tests by type (unit, integration, system)
5. Any test files that are particularly slow (> 5 seconds)

Store these metrics in the workflow state for later comparison in post-processing.

Output format:
```json
{
  "total_test_files": 0,
  "overall_coverage": 0.0,
  "average_execution_time": 0.0,
  "test_counts": {
    "unit": 0,
    "integration": 0,
    "system": 0
  },
  "slow_tests": []
}
```