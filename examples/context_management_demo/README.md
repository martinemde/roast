# Context Management Demo

This example demonstrates Roast's automatic context management feature, which helps prevent workflow failures when conversation history exceeds the LLM's context window.

## Features Demonstrated

1. **Automatic Token Tracking**: Monitors token usage throughout workflow execution
2. **Configurable Thresholds**: Set when to trigger warnings or compaction
3. **Context Preservation**: Specify critical steps to retain during compaction
4. **Multiple Compaction Strategies**: Choose how context is reduced

## Available Strategies

### 1. Auto Strategy (default)
Uses an LLM to analyze the transcript and intelligently select the best strategy:
- Examines conversation structure and content
- Considers tool usage and message patterns
- Makes context-aware decisions
- Falls back to summarize if analysis fails

### 2. Summarize Strategy
Uses AI to create intelligent summaries of older messages:
- Preserves key decisions and outcomes
- Maintains context continuity
- Best for complex workflows with important history

### 3. FIFO Strategy (First In, First Out)
Removes oldest messages while keeping recent ones:
- Simple and predictable
- Preserves recent context
- Configurable keep percentage
- Best for long-running workflows

### 4. Prune Strategy
Keeps beginning and end, removes middle messages:
- Preserves initial context (requirements, setup)
- Maintains recent state
- Configurable start/end counts
- Best for workflows with important setup phase

## Configuration

```yaml
context_management:
  enabled: true          # Enable context management
  strategy: auto         # Options: auto, summarize, fifo, prune
  threshold: 0.8         # Trigger at 80% of context window
  max_tokens: 10000      # Override default limit (for demo purposes)
  
  # Strategy-specific options:
  
  # For auto:
  analysis_model: o4-mini  # Model to use for strategy selection
  
  # For summarize/auto:
  retain_steps:          # Steps to always keep in full
    - analyze_requirements
    - generate_summary
    
  # For FIFO:
  keep_percentage: 0.5   # Keep 50% of most recent messages
  
  # For prune:
  keep_start: 5          # Keep first 5 messages
  keep_end: 20           # Keep last 20 messages
```

## Running the Demo

```bash
roast execute context_management_demo
```

The workflow intentionally generates verbose responses to demonstrate how context management handles large amounts of text without failing.

## What to Observe

1. **Token Usage Warnings**: Watch for warnings as the context approaches limits
2. **Automatic Handling**: The workflow continues even with large outputs
3. **Preserved Context**: Critical steps remain accessible throughout execution

## Customization

Try modifying the configuration:
- Lower `max_tokens` to trigger compaction sooner
- Change `strategy` to test different compaction approaches
- Add more steps to `retain_steps` to preserve additional context