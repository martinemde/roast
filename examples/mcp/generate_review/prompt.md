Generate a structured code review with:
{
  "summary": "Overall assessment",
  "approval_status": "approve|request_changes|comment",
  "issues": [
    {
      "severity": "critical|major|minor",
      "file": "filename",
      "line": 123,
      "description": "Issue description",
      "suggestion": "How to fix"
    }
  ],
  "positive_feedback": ["What was done well"],
  "documentation_updates": ["Required doc changes"]
}