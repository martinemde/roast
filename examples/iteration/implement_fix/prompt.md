I'll implement the fix for the issue selected in the previous step.

Here is the issue to fix:
```json
<%= output.select_next_issue %>
```

First, I'll read the current file content to understand the context:

```ruby
<%= read_file(output.select_next_issue.file_path) %>
```

Based on the issue description and the recommended changes, I'll implement a fix that:
1. Addresses the specific issue identified
2. Follows Ruby best practices and style conventions
3. Is minimal and focused (changes only what's necessary)
4. Maintains or improves the existing functionality

I'll use the update_files tool to apply the changes. For each change, I'll provide:
1. The file path
2. The changes to make
3. A detailed explanation of what was changed and why

After implementing the fix, I'll return a summary of the changes made.