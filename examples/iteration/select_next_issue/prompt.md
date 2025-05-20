I'll select the next highest priority issue to fix from our prioritized list.

Here is the current prioritized list of issues:
```json
{{output.prioritize_issues}}
```

And here is the count of fixes we've already applied:
```
{{output.update_fix_count || '0'}}
```

I'll select the highest priority issue that hasn't yet been addressed. I'll consider:

1. The priority score from our previous analysis
2. Dependencies between issues (ensuring prerequisites are addressed first)
3. Logical grouping (addressing related issues in the same file together)

If there are no issues left to fix, I'll indicate this with `{"no_issues_left": true}`.

For the selected issue, I'll return:
1. The issue details
2. The file path to modify
3. A clear description of the changes needed
4. Any context needed for implementation