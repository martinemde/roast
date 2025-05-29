# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] - 2025-05-28

### Added
- Pre/post processing framework for workflows with `pre_processing` and `post_processing` sections
- Support for `output.txt` ERB templates in post-processing phase for custom output formatting
- Pre/post processing support for single-target workflows (not just multi-target)
- Simplified access to pre-processing data in target workflows (removed `output` intermediary level)

## [0.2.1]

### Added
- Smart coercion defaults for boolean expressions based on step type
  - Ruby expressions (`{{expr}}`) default to regular boolean coercion
  - Bash commands (`$(cmd)`) default to exit code interpretation
  - Inline prompts and regular steps default to "smart" LLM-powered interpretation (looks for truthy or falsy language)
- Direct syntax for step configuration - `coerce_to` and other options are now specified directly on iteration steps

## [0.2.0] - 2025-05-26

### Added
- Conditional execution support with `if` and `unless` clauses for workflow steps
- Iteration mechanisms for workflows with `repeat` and `each` constructs (resolving issue #48)
- Support for conditional repetition with `until` condition and safety limits
- Collection iteration with variable binding for processing lists of items
- State persistence for loop iterations to enable resumption after failure
- Standardized evaluation of Ruby expressions in iteration constructs using `{{}}` syntax
- Support for using bash commands, step names, and Ruby expressions in iteration conditions and collections
- Intelligent LLM response to boolean conversion with pattern-based recognition for natural language responses
- `exit_on_error` configuration option for command steps to continue workflow on failure (resolving issue #71)
- Dot notation access for workflow outputs (e.g., `workflow.output.step.field`)
- `--pause` flag for stepping through workflow execution interactively

### Fixed
- Automatically add `.gitignore` file to cache directory when created (completing issue #22)
- Load initializers before trying to load tools in case custom tools are defined in initializers (thanks @palkan)
- Fix loading of targetless workflows (thanks @palkan)
- Fix OpenRouter support (thanks @xrendan)
- API authentication error handling and model access issues
- Conditional step transcript replay regression
- DotAccessHash serialization for AI prompts

### Improved
- Enhanced search file tool logging to show full expanded paths instead of relative paths
- Major refactoring to eliminate circular dependencies and improve architecture
- Extracted command execution logic into dedicated CommandExecutor class
- Separated conditional execution from iteration logic for better SOLID compliance
- Enhanced error messages for API authentication failures
- Replaced all `require_relative` with `require` statements for consistency

### Changed
- Refactored god objects to improve code organization and maintainability
- Improved separation of concerns between workflow components

[0.2.0]: https://github.com/Shopify/roast/compare/v0.1.7...v0.2.0

## [0.1.7] - 2024-05-16

### Added
- `UpdateFiles` tool for applying diffs/patches to multiple files at once
- Support for atomic file updates with rollback capability
- Comprehensive documentation for all built-in tools
- Enhanced README with detailed tool usage examples

``[0.1.7]: https://github.com/Shopify/roast/compare/v0.1.6...v0.1.7

## [0.1.6] - 2024-05-15

### Added
- Support for OpenRouter as an API provider
- `api_provider` configuration option allowing choice between OpenAI and OpenRouter
- Added separate CI rake task for improved build pipeline
- Version command to check current Roast version
- Walking up to home folder for config root
- Improved initializer support for better project configuration

### Changed
- Enhanced search tool to work with globs for more flexible searches
- Improved error handling in configuration and initializers
- Fixed and simplified interpolation examples

### Fixed
- Better error messages for search file tool
- Improved initializer loading and error handling
- Fixed tests for nested .roast folders

[0.1.6]: https://github.com/Shopify/roast/compare/v0.1.5...v0.1.6

## [0.1.5] - 2024-05-13

### Added
- Interpolation feature for dynamic workflows using `{{}}` syntax
- Support for injecting values from workflow context into step names and commands
- Ability to access file metadata and step outputs using interpolation expressions
- Examples demonstrating interpolation usage with different file types

[0.1.5]: https://github.com/Shopify/roast/releases/tag/v0.1.5

## [0.1.4] - 2024-05-13

### Fixed
- Remove test directory restriction from WriteTool. (Thank you @endoze)

[0.1.4]: https://github.com/Shopify/roast/releases/tag/v0.1.4


## [0.1.3] - 2024-05-12

### Fixed
- ReadFile tool now handles absolute and relative paths correctly

[0.1.3]: https://github.com/Shopify/roast/releases/tag/v0.1.3


## [0.1.2] - 2024-05-09

### Fixed
- problem with step loading using `--replay` option
- made access to `workflow.output` more robust by using hash with indifferent access

[0.1.2]: https://github.com/Shopify/roast/releases/tag/v0.1.2

## [0.1.1] - 2024-05-09

### Added
- Initial public release of Roast, extracted from Shopify's internal AI orchestration tools
- Core workflow execution engine for structured AI interactions
- Step-based workflow definition system
- Instrumentation hooks for monitoring and debugging
- Integration with various LLM providers (via [Raix](https://github.com/OlympiaAI/raix))
- Schema validation for workflow inputs and outputs
- Command-line interface for running workflows
- Comprehensive documentation and examples

[0.1.1]: https://github.com/Shopify/roast/releases/tag/v0.1.1
