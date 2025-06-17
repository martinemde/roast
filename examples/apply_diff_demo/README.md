# Apply Diff Demo

This example demonstrates the `apply_diff` tool, which shows users a colored diff of proposed changes and applies them only after user confirmation.

## What this workflow does

1. **Creates a sample file** - Generates `hello.txt` with simple text content
2. **Applies a simple change** - Uses `apply_diff` to modify the greeting and ask for user confirmation

## Key features demonstrated

- **Interactive approval** - The `apply_diff` tool shows a clear, colored diff and waits for user confirmation
- **Safe modifications** - Changes are only applied when the user explicitly approves them
- **Colored visualization** - Diff format shows exactly what will be changed with:
  - **Red** lines starting with `-` for removed content
  - **Green** lines starting with `+` for added content  
  - **Cyan** line numbers and context (`@@` lines)
  - **Bold** diff headers
- **Optional descriptions** - You can provide context about why a change is being made

## Running the workflow

```bash
bin/roast examples/apply_diff_demo/workflow.yml
```

## Expected interaction

When you run this workflow, you'll see:

1. The workflow creates a simple `hello.txt` file
2. It proposes changing "Hello World!" to "Hello, Apply Diff Demo!"
3. It shows you a colored diff of the proposed change:
   ```
   📝 Proposed change for hello.txt:
   Description: Update greeting to be more specific to the demo
   
   diff --git a/hello.txt b/hello.txt
   index 1234567..abcdefg 100644
   --- a/hello.txt
   +++ b/hello.txt
   @@ -1,3 +1,3 @@
   -Hello World!
   +Hello, Apply Diff Demo!
    This is a demo file.
    We will modify this file in the next step.
   ```
4. It asks for your confirmation: `Apply this change? (y/n)`
5. If you say "y", it applies the change; if "n", it cancels
6. Finally, it reads the file again to show the result

## Tools used

- `Roast::Tools::WriteFile` - Creates the initial sample file
- `Roast::Tools::ReadFile` - Reads files to show results
- `Roast::Tools::ApplyDiff` - Shows colored diffs and applies changes with user confirmation

This pattern is useful for any workflow where you want to make targeted changes to files but give users control over what actually gets applied.