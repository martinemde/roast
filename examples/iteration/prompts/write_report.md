# Write Method Analysis Report

You are responsible for creating a formatted report file based on the analysis results.

## Input
- Report data: {{ report_data }}
- Summary: {{ summary }}

## Task
1. Generate a Markdown report that includes:
   - The summary information
   - A detailed table of all files analyzed, with their method counts and method names
2. Format the report in a clean, readable manner

## Response Format
Return a JSON object with the following structure:
```json
{
  "report_content": "# Ruby Method Analysis Report\n\n{{ summary }}\n\n## Detailed Results\n\n| File | Method Count | Methods |\n|------|--------------|--------|\n| file1.rb | 5 | method1, method2, ... |\n| file2.rb | 3 | methodA, methodB, ... |\n...",
  "report_file_path": "method_analysis_report.md"
}
```