# Environment Analysis

Use the bash tool to analyze the development environment in ways that require unrestricted access.

Perform these analyses:

1. **Ruby Environment**:
   - Check Ruby version: `ruby --version`
   - List installed Ruby versions: `rbenv versions 2>/dev/null || rvm list 2>/dev/null || echo "No Ruby version manager detected"`
   - Show gem environment: `gem env | grep -E "RUBY|GEM|PATH" | head -10`

2. **Git Repository Analysis**:
   - Show git configuration: `git config --list | grep -E "user|remote" | head -5`
   - Check for any git hooks: `ls -la .git/hooks/ 2>/dev/null | grep -v "\.sample$" || echo "No custom hooks"`
   - Show branch information: `git branch -a | head -10`

3. **Development Tools**:
   - Check for common dev tools: `for cmd in node npm yarn docker make; do which $cmd && echo "$cmd is installed" || echo "$cmd not found"; done`
   - Check environment variables: `env | grep -E "PATH|RUBY|GEM" | head -5`

4. **File System Analysis**:
   - Find large files: `find . -type f -size +1M 2>/dev/null | head -5 || echo "No large files found"`
   - Count files by extension: `find . -type f -name "*.rb" 2>/dev/null | wc -l | xargs echo "Ruby files:"`

RESPONSE FORMAT
Provide your analysis in JSON:

<json>
{
  "environment_analysis": {
    "ruby_setup": {
      "version": "Current Ruby version",
      "version_manager": "rbenv/rvm/none",
      "gem_path": "Primary gem installation path"
    },
    "git_configuration": {
      "user_configured": true,
      "custom_hooks": false,
      "branch_count": 5
    },
    "development_tools": {
      "available": ["List of installed tools"],
      "missing": ["List of tools not found"]
    },
    "project_metrics": {
      "ruby_files_count": 100,
      "large_files_found": 3
    }
  },
  "insights": "Summary of what this analysis reveals about the development environment"
}
</json>