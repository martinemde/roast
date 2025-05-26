# Cleanup Environment

Perform post-optimization cleanup tasks:

1. **Commit Changes**: Create a commit with all the test improvements
   - Use a descriptive commit message summarizing the optimization results
   - Include key metrics in the commit description

2. **Update Documentation**:
   - Update test documentation if structure changed significantly
   - Add notes about any new test helpers or patterns introduced

3. **Clean Temporary Files**:
   - Remove any temporary files created during optimization
   - Clear test caches that were used for benchmarking

4. **Final Verification**:
   - Run the full test suite one more time to ensure everything works
   - Verify CI/CD pipelines will work with the changes

5. **Create PR Description**:
   - Generate a pull request description template with:
     - Summary of changes
     - Key metrics improvements
     - Any breaking changes or considerations
     - Review checklist

Output a summary of cleanup actions performed and any final notes for the team.