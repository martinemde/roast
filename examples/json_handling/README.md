# JSON Handling Example

This example demonstrates how Roast handles JSON responses from LLM steps.

## Key Features

1. **JSON Arrays**: When a step has `json: true` and returns an array, the result is `flatten.first` - the first element after flattening the array. This is useful when the LLM returns an array with a single object.

2. **JSON Objects**: Hash/object responses are maintained as proper Ruby hashes in the workflow output.

3. **Replay Support**: JSON data structures are properly serialized and deserialized when saving/loading workflow state for replay functionality.

## Running the Example

```bash
bin/roast examples/json_handling/workflow.yml
```

## How It Works

1. The `fetch_users` step generates a JSON array of user objects
2. The `fetch_metadata` step generates a JSON object with metadata
3. The `process_data` step can access the structured data using `{{output.fetch_users}}` and `{{output.fetch_metadata}}`
4. The structured data is preserved through the workflow, including during replay scenarios

## Implementation Details

When `json: true` is set on a step:
- Array responses return `flatten.first` - the first element after flattening
- Object responses are preserved as hashes
- Non-JSON array responses (when `json: false`) are joined with newlines
- The data maintains its structure when saved to and loaded from workflow state files