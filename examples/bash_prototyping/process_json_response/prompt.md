# Process JSON Responses

Use bash with jq (if available) to process JSON responses:

1. First check if jq is installed:
   ```bash
   which jq
   ```

2. If jq is available, use it to parse JSON:
   ```bash
   curl -s https://api.github.com/users/github | jq '.name, .public_repos'
   ```

3. If jq is not available, use alternative methods like:
   - grep with regular expressions
   - sed/awk for parsing
   - Python one-liners if Python is available

4. Extract specific fields from the API responses
5. Count items in arrays
6. Filter data based on conditions

Show different approaches for JSON processing depending on available tools.