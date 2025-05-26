# Pre/Post Processing Example: Test Suite Optimization

This example demonstrates how to use Roast's pre/post processing framework to optimize an entire test suite across multiple files.

## Overview

The workflow processes multiple test files, but performs setup and aggregation tasks only once:

- **Pre-processing**: Runs once before any test files are processed
  - Gathers baseline metrics for comparison
  - Sets up the test environment
  
- **Main workflow**: Runs for each test file matching the target pattern
  - Analyzes test quality and coverage
  - Improves test coverage
  - Optimizes test performance
  - Validates changes
  
- **Post-processing**: Runs once after all test files have been processed
  - Aggregates metrics from all files
  - Generates a comprehensive report
  - Cleans up the environment

## Workflow Structure

```yaml
name: test_optimization
model: gpt-4o
target: "test/**/*_test.rb"

pre_processing:
  - gather_baseline_metrics
  - setup_test_environment

steps:
  - analyze_test_file
  - improve_test_coverage
  - optimize_test_performance
  - validate_changes

post_processing:
  - aggregate_metrics
  - generate_summary_report
  - cleanup_environment
```

## Directory Structure

```
pre_post_processing/
├── workflow.yml
├── pre_processing/
│   ├── gather_baseline_metrics/
│   │   └── prompt.md
│   └── setup_test_environment/
│       └── prompt.md
├── analyze_test_file/
│   └── prompt.md
├── improve_test_coverage/
│   └── prompt.md
├── optimize_test_performance/
│   └── prompt.md
├── validate_changes/
│   └── prompt.md
└── post_processing/
    ├── aggregate_metrics/
    │   └── prompt.md
    ├── generate_summary_report/
    │   └── prompt.md
    └── cleanup_environment/
        └── prompt.md
```

## Key Features Demonstrated

1. **Shared State**: Pre-processing results are available to all subsequent steps
2. **Result Aggregation**: Post-processing has access to results from all workflow executions
3. **One-time Operations**: Setup and cleanup happen only once, regardless of target count
4. **Metrics Collection**: Each file's results are stored and aggregated for reporting

## Running the Example

```bash
cd examples/pre_post_processing
roast workflow.yml
```

This will:
1. Run pre-processing steps once
2. Process each test file matching `test/**/*_test.rb`
3. Run post-processing steps once with access to all results
4. Generate a comprehensive optimization report

## Use Cases

This pattern is ideal for:
- **Code migrations**: Setup migration tools, process files, generate migration report
- **Performance audits**: Baseline metrics, analyze files, aggregate improvements
- **Documentation generation**: Analyze codebase, generate docs per file, create index
- **Dependency updates**: Check current versions, update files, verify compatibility
- **Security scanning**: Setup scanners, check each file, generate security report

## Customization

To adapt this example for your use case:

1. Update the `target` pattern to match your files
2. Modify pre-processing steps for your setup needs
3. Adjust main workflow steps for your processing logic
4. Customize post-processing for your reporting requirements
5. Use appropriate AI models for each step type