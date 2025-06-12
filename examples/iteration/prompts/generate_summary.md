# Generate Method Analysis Summary

You are a report generator responsible for summarizing the method analysis results.

## Input
- Report data: <%= report_data %>

## Task
1. Parse the report data as JSON
2. Create a summary of the analysis results including:
   - Total number of files analyzed
   - Total number of methods found
   - Average number of methods per file
   - File with the most methods
   - File with the fewest methods
3. Generate a formatted summary text

## Response Format
Return a JSON object with the following structure:
```json
{
  "summary": "## Ruby Method Analysis Summary\n\nAnalyzed 10 Ruby files in the workflow directory.\n- Total methods found: 45\n- Average methods per file: 4.5\n- Most methods: base_workflow.rb (12 methods)\n- Fewest methods: state_repository.rb (1 method)\n\n### Top 3 Files by Method Count\n1. base_workflow.rb: 12 methods\n2. configuration.rb: 8 methods\n3. workflow_executor.rb: 7 methods\n"
}
```