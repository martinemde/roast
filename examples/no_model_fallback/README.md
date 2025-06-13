# No Model Fallback Example

This example demonstrates the issue where workflows without explicit model specification do not properly fall back to a default model.

## Purpose

This workflow is based on the interpolation example but intentionally omits the `model` field to test the fallback behavior.

## Expected Behavior

The workflow should fall back to a default model when no model is specified at the workflow level.

## Usage

```bash
bin/roast examples/no_model_fallback/workflow.yml --file examples/no_model_fallback/sample.rb
```