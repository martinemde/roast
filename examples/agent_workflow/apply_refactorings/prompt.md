Based on the code smells identified in the previous step, apply the following refactorings:

For each file that needs changes:

1. Use the Read tool to examine the current implementation
2. Use MultiEdit to apply all refactorings in a single operation per file
3. Ensure all changes maintain exact formatting and indentation
4. Focus on these specific refactorings:
   - Extract long methods (>15 lines) into smaller, focused methods
   - Replace magic numbers with named constants
   - Rename variables/methods that don't clearly express intent
   - Extract duplicate code into shared methods
   - Add proper error handling where missing

Important constraints:
- DO NOT change the public API of any class
- DO NOT modify test files
- DO NOT add comments unless replacing unclear code
- Preserve all existing functionality
- Use Ruby idioms and conventions

After each file modification, verify the changes maintain the original behavior.