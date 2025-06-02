# Demonstrate Bash Flexibility

Show advanced bash capabilities that highlight why unrestricted access is useful for prototyping.

Demonstrate these advanced operations:

1. **Complex Shell Operations**:
   - Create a temporary analysis: `echo "Analysis started at $(date)" > /tmp/roast_bash_demo.txt`
   - Append system info: `echo "Running on $(uname -s) with $(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo "unknown") cores" >> /tmp/roast_bash_demo.txt`
   - Show the analysis: `cat /tmp/roast_bash_demo.txt`
   - Clean up: `rm -f /tmp/roast_bash_demo.txt`

2. **Data Processing Pipeline**:
   - Count code lines: `find . -name "*.rb" -type f 2>/dev/null | xargs wc -l 2>/dev/null | tail -1 || echo "0 total"`
   - Generate a quick report: `echo "Project has $(find . -name "*.rb" -type f 2>/dev/null | wc -l) Ruby files with $(find . -name "*_test.rb" -type f 2>/dev/null | wc -l) test files"`

3. **Advanced Text Processing**:
   - Extract and count TODOs: `grep -r "TODO" --include="*.rb" . 2>/dev/null | wc -l | xargs echo "TODO comments found:"`
   - Find recent changes: `find . -name "*.rb" -type f -mtime -7 2>/dev/null | wc -l | xargs echo "Ruby files modified in last 7 days:"`

4. **Conditional Operations**:
   - Check and report: `if [ -f "Gemfile.lock" ]; then echo "Project uses Bundler with $(grep -c "  " Gemfile.lock) dependencies"; else echo "No Gemfile.lock found"; fi`
   - Test for CI config: `for ci in ".github/workflows" ".circleci" ".travis.yml"; do [ -e "$ci" ] && echo "Found CI config: $ci" || true; done`

Remember to show both the power and responsibility of unrestricted bash access.

RESPONSE FORMAT
Summarize the demonstrations in JSON:

<json>
{
  "flexibility_demonstrated": {
    "complex_operations": [
      "List of complex operations performed"
    ],
    "data_processing": {
      "total_ruby_lines": 10000,
      "ruby_files": 150,
      "test_files": 75
    },
    "project_insights": {
      "todos_found": 12,
      "recent_changes": 8,
      "uses_bundler": true,
      "ci_configured": true
    },
    "capabilities_shown": [
      "File system operations",
      "Complex pipelines",
      "Conditional logic",
      "Text processing",
      "System integration"
    ]
  },
  "conclusion": "Summary of why bash tool is valuable for prototyping while acknowledging security considerations"
}
</json>