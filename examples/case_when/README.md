# Case/When/Else Example

This example demonstrates the use of `case/when/else` control flow in Roast workflows.

## Overview

The `case/when/else` construct allows you to execute different steps based on the value of an expression, similar to Ruby's case statement or switch statements in other languages.

## Syntax

```yaml
- case: <expression>
  when:
    <value1>:
      - <steps>
    <value2>:
      - <steps>
  else:
    - <steps>
```

## Features Demonstrated

1. **Basic case/when/else**: Detect file language and execute language-specific analysis
2. **Bash command evaluation**: Use environment variables to determine deployment strategy
3. **Complex expressions**: Use Ruby expressions to categorize numeric values

## Expression Types

The `case` expression can be:
- A simple string value
- An interpolated workflow output: `{{ workflow.output.variable }}`
- A Ruby expression: `{{ workflow.output.count > 10 ? 'high' : 'low' }}`
- A bash command: `$(echo $ENVIRONMENT)`
- A reference to a previous step's output

## How It Works

1. The `case` expression is evaluated to produce a value
2. The value is compared against each key in the `when` clause
3. If a match is found, the steps under that key are executed
4. If no match is found and an `else` clause exists, those steps are executed
5. If no match is found and no `else` clause exists, execution continues

## Running the Example

```bash
roast execute examples/case_when/workflow.yml
```

This will process all Ruby, JavaScript, Python, and Go files in the current directory, detecting their language and running appropriate analysis steps.

## Use Cases

- **Multi-language projects**: Different linting/testing for different file types
- **Environment-specific workflows**: Different deployment steps for prod/staging/dev
- **Conditional processing**: Different handling based on file size, complexity, or other metrics
- **Error handling**: Different recovery strategies based on error types