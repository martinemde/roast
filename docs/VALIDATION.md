# Workflow Validation

Roast provides comprehensive validation for workflow configurations to catch errors early and improve the development experience.

## Using the Validation Command

### Validate a Single Workflow

```bash
# Validate a specific workflow by path
roast validate path/to/workflow.yml

# Or by workflow name (assumes roast/ directory structure)
roast validate my_workflow
```

### Validate All Workflows

```bash
# Validate all workflows in the roast/ directory
roast validate
```

### Strict Mode

Use the `--strict` or `-s` flag to treat warnings as errors:

```bash
roast validate --strict
```

## Validation Levels

### 1. Schema Validation

Ensures your workflow conforms to the JSON schema:
- Required fields (name, tools, steps)
- Correct data types
- Valid structure for complex steps (if/then, case/when, each, repeat)

### 2. Dependency Checking

#### Tool Dependencies
Validates that all declared tools are available:
- Checks for tool module existence
- Supports MCP tool configurations
- Provides helpful suggestions for typos

#### Step References
Validates that steps referenced in conditions exist:
- Checks `if`, `unless`, and `case` conditions
- Distinguishes between step references and expressions

#### Resource Dependencies
Validates file resources:
- Warns if target files don't exist (unless using glob patterns)
- Checks for missing prompt files

### 3. Configuration Linting

#### Naming Conventions
- Workflows should have descriptive names
- Step names should use snake_case

#### Complexity Checks
- Warns about workflows with too many steps (>20)
- Detects excessive nesting depth (>5 levels)

#### Security Warnings
- Detects hardcoded API keys, passwords, tokens, and secrets
- Suggests using inputs or environment variables

#### Best Practices
- Warns about missing error handling
- Detects unused tool declarations

## Error Messages

The validator provides clear, actionable error messages:

```
Workflow validation failed with 2 error(s):

• Missing required field: 'steps' (Add 'steps' to your workflow configuration)
• Tool 'Roast::Tools::BashCommand' is not available (Did you mean: Roast::Tools::Bash?)
```

## Example Workflow

Here's an example of a well-validated workflow:

```yaml
name: Data Processing Workflow
tools:
  - Roast::Tools::Bash
  - Roast::Tools::ReadFile
  - Roast::Tools::WriteFile

# Use inputs for sensitive data
inputs:
  - api_token: "Enter your API token"

# Enable error handling
exit_on_error: true

steps:
  - validate_input
  - fetch_data
  - process_data
  - save_results
```

## Integration with CI/CD

You can integrate workflow validation into your CI/CD pipeline:

```yaml
# .github/workflows/validate.yml
name: Validate Workflows
on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.0'
          bundler-cache: true
      - name: Validate all workflows
        run: bundle exec roast validate --strict
```

## Programmatic Usage

You can also use the validator programmatically:

```ruby
require 'roast'

yaml_content = File.read('workflow.yml')
validator = Roast::Workflow::ComprehensiveValidator.new(yaml_content, 'workflow.yml')

if validator.valid?
  puts "Workflow is valid!"
  
  # Check for warnings
  validator.warnings.each do |warning|
    puts "Warning: #{warning[:message]}"
    puts "  → #{warning[:suggestion]}"
  end
else
  # Handle errors
  validator.errors.each do |error|
    puts "Error: #{error[:message]}"
    puts "  → #{error[:suggestion]}"
  end
end
```

## Future Enhancements

The validation system is designed to be extensible. Future enhancements may include:

- Detection of circular dependencies
- Performance analysis and optimization suggestions
- Custom validation rules via plugins
- Integration with language servers for real-time validation