# Iteration Mechanisms Implementation

This document provides an overview of how the iteration mechanisms are implemented in Roast.

## Core Components

### 1. Schema Extensions

The workflow schema has been extended to support two new iteration constructs:

- **Repeat** - For conditional repetition until a condition is met
- **Each** - For iterating over collections with a variable binding

These schema extensions define the structure and validation rules for the iteration YAML syntax.

### 2. Step Classes

Two new step classes handle the actual iteration logic:

- **RepeatStep** - Executes steps repeatedly until a condition is met or a maximum iteration count is reached
- **EachStep** - Iterates over a collection, binding each item to a variable, and executes steps for each item

Both inherit from a common `BaseIterationStep` class that provides shared functionality.

### 3. Pattern Matching

The `WorkflowExecutor` has been enhanced with pattern matching to recognize the `repeat` and `each` keywords and dispatch to the appropriate step classes:

```ruby
case name
when "repeat"
  execute_repeat_step(command)
when "each"
  # Handle 'each' step with its special format
  execute_each_step(step)
else
  # Handle regular steps
end
```

### 4. State Management

Both iteration types include state management to:

- Track current iteration number
- Save state after each iteration
- Support resumption after failures
- Provide safety limits against infinite loops

## Iteration Flow

### RepeatStep Flow

1. Start with iteration count = 0
2. Execute the nested steps in sequence
3. Evaluate the until condition
4. If condition is true or max_iterations is reached, stop
5. Otherwise, increment iteration count and go back to step 2
6. Return the results of all iterations

### EachStep Flow

1. Resolve the collection expression
2. For each item in the collection:
   a. Set the named variable (accessible in steps through a getter method)
   b. Execute the nested steps
   c. Save state
3. Return the results from all iterations

## Safety Mechanisms

- **max_iterations** parameter prevents infinite loops
- State is saved after each iteration for resumption capability
- Robust error handling during condition evaluation and step execution
- Collection type checking ensures iterable objects

## Usage Examples

The workflow.yml and step files in this directory demonstrate practical applications of these iteration mechanisms for code quality analysis.

## Integration with Existing Workflow Engine

The iteration mechanism integrates seamlessly with the existing workflow engine:

- Uses the same state persistence mechanisms
- Follows the same execution models
- Maintains compatibility with all existing steps
- Supports interpolation within iteration constructs