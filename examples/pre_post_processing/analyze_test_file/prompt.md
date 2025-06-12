# Analyze Test File

Current test file: <%= file %>

Please analyze this test file and identify:

1. **Test Structure**: Number of test cases, test suites, and overall organization
2. **Coverage Gaps**: Areas of the code that aren't adequately tested
3. **Test Quality Issues**:
   - Tests that are too brittle or implementation-dependent
   - Missing edge cases
   - Unclear test descriptions
   - Excessive mocking that reduces test value
4. **Performance Issues**:
   - Slow setup/teardown methods
   - Inefficient test data generation
   - Unnecessary database operations
5. **Opportunities for Improvement**:
   - Tests that could be parameterized
   - Common patterns that could be extracted to helpers
   - Better use of test fixtures or factories

Provide specific, actionable recommendations for each issue found.