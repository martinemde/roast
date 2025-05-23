# Simple Iteration Workflow Example

This example demonstrates how to use both the `each` and `repeat` iteration constructs in Roast workflows.

## Workflow Description

The workflow analyzes Ruby files in the `lib/roast/workflow` directory and counts the number of methods defined in each file. The process follows these steps:

1. Find all Ruby files in the specified directory
2. Initialize a report object to store our results
3. Process each file found:
   - Read the file content
   - Count the methods defined
   - Update the report with the analysis result
4. Generate a summary report
5. Write the report to a file

## Key Components

- `each` construct: Processes every Ruby file found in the directory
- `repeat` construct: Used to generate the final summary (demonstrates a simple case of the repeat construct)
- Both block-level and prompt-based steps

## Running the Workflow

To run this workflow, use the following command:

```bash
shadowenv exec -- bundle exec roast examples/iteration/simple_workflow.yml
```

The final report will be saved to a markdown file as specified in the output of the `write_report` step.

## Learning Objectives

- Understand how to use the `each` construct to iterate over a collection
- Understand how to use the `repeat` construct for conditional repetition
- Learn how to build and update data structures across workflow steps
- See how to pass data between steps in an iteration workflow