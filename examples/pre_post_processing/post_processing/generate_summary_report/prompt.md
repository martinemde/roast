# Generate Summary Report

Generate a comprehensive test optimization report based on all the collected data:

## Test Suite Optimization Report

### Executive Summary
Provide a high-level overview of the optimization results, key achievements, and any issues encountered.

### Metrics Summary
Include the aggregated metrics from the previous step:
{{aggregate_metrics}}

### Detailed Results by File
For each processed test file, include:
- File name and path
- Coverage improvement
- Performance improvement
- Number of tests added/modified
- Key changes made

### Recommendations
Based on the optimization results, provide:
1. Further optimization opportunities
2. Best practices observed that should be adopted project-wide
3. Common patterns that could be extracted into shared utilities
4. Testing strategy improvements

### Next Steps
Suggest follow-up actions to maintain and build upon these improvements.

Format the report in Markdown for easy sharing and include visual indicators (✅ ❌ ⚠️) for quick scanning.