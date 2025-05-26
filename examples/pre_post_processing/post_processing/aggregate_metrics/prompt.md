# Aggregate Metrics

Aggregate all the metrics collected during the workflow execution:

Available data:
- Pre-processing baseline metrics: {{pre_processing_results.gather_baseline_metrics}}
- Results from all processed test files: {{all_workflow_results}}

Please calculate and provide:

1. **Overall Coverage Improvement**:
   - Total coverage before and after
   - Percentage improvement
   - Files with biggest improvements

2. **Performance Gains**:
   - Total execution time saved
   - Average performance improvement per file
   - Files with best optimization results

3. **Test Quality Metrics**:
   - Number of new tests added
   - Number of tests optimized
   - Reduction in flaky/brittle tests

4. **Summary Statistics**:
   - Total files processed
   - Success rate
   - Any files that had issues

Output a comprehensive metrics summary that can be used in the final report.