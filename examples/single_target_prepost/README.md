# Single Target with Pre/Post Processing Example

This example demonstrates how pre/post processing works with single-target workflows. Even when analyzing just one file, you can use pre-processing to gather context and post-processing to format results.

## Features Demonstrated

1. **Pre-processing for context gathering** - Analyze dependencies before the main workflow
2. **Single-target analysis** - Focus on one specific file
3. **Post-processing with output template** - Custom formatting of the final report

## Running the Example

```bash
roast workflow.yml
```

This will:
1. Run pre-processing to gather dependencies and context
2. Analyze the single target file (src/main.rb)
3. Apply the post-processing template to format the output

## Output Template

The `post_processing/output.txt` template demonstrates how to:
- Access pre-processing results with `<%= pre_processing[:step_name] %>`
- Iterate over target results (even for single targets)
- Include post-processing step outputs
- Format everything into a professional report

## Use Cases

This pattern is ideal for:
- Deep analysis of critical files
- Security audits of specific components
- Performance profiling of key modules
- Generating documentation for important classes