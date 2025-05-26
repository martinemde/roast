# Detect Programming Language

Based on the file extension and content, determine the primary programming language of this file:
- If it's a `.rb` file, return "ruby"
- If it's a `.js` file, return "javascript"
- If it's a `.py` file, return "python"
- If it's a `.go` file, return "go"
- Otherwise, return "unknown"

Return ONLY the language name in lowercase, nothing else.

File: {{ context.resource_uri }}
Content:
```
{{ context.resource }}
```