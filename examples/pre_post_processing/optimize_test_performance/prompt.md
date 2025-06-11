# Optimize Test Performance

Optimize the performance of <%= file %> by:

1. **Reduce Setup Overhead**:
   - Move expensive operations out of individual test setup
   - Use shared fixtures where appropriate
   - Lazy-load test data only when needed

2. **Optimize Database Operations**:
   - Use transactions for test isolation instead of truncation
   - Minimize database queries in tests
   - Use in-memory databases where possible

3. **Improve Test Isolation**:
   - Remove unnecessary dependencies between tests
   - Clean up resources properly to avoid test pollution
   - Use proper test doubles instead of hitting external services

4. **Parallelize When Possible**:
   - Identify tests that can run in parallel
   - Remove shared state that prevents parallelization
   - Group related tests for better cache utilization

Generate the optimized test code and provide before/after performance metrics estimates.