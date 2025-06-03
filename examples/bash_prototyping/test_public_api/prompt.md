# Test Public API Endpoints

Use the bash tool to test various public APIs:

1. Test GitHub API:
   ```bash
   curl -s https://api.github.com/users/github
   ```

2. Test a public JSON placeholder API:
   ```bash
   curl -s https://jsonplaceholder.typicode.com/posts/1
   ```

3. Check response headers:
   ```bash
   curl -I https://api.github.com
   ```

4. Test with different HTTP methods if appropriate

Analyze the responses and note the structure of the returned data.