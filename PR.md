# Improve Game Testing Infrastructure and Documentation

## Summary
This PR introduces a comprehensive testing infrastructure for the Vanilla game, enabling systematic verification of all game mechanics through a unified test runner. It addresses previous issues with the game simulator tests, standardizes testing procedures, and provides detailed documentation.

## Key Features

### Unified Test Runner (`bin/run_tests`)
- Created a comprehensive script that executes all testing mechanisms in a single command
- Generates detailed logs and summary reports for each test run
- Supports customization options (verbose mode, fast execution, seed selection)
- Provides proper exit codes for CI/CD integration

### Enhanced Game Test Script (`bin/test_game`)
- Fixed parameter order issues with `MoveCommand` causing frequent test failures
- Improved error handling and reporting
- Added deterministic stairs testing with guaranteed level transitions
- Implemented robust error handling for complex test scenarios

### Documentation
- Created `doc/testing.md` with detailed usage instructions for test tools
- Updated command documentation to reference testing guidelines
- Added troubleshooting information for common issues
- Provided examples for extending the test infrastructure

### CI/CD Improvements
- Updated GitHub Actions workflow to use the comprehensive test runner
- Added test artifacts collection for better debugging of CI failures
- Improved job naming and organization for better visibility
- Enabled bundler caching for faster workflow execution

## Technical Changes
- Reorganized test execution to run RSpec tests last with direct console output
- Added proper output capturing and logging for all test types
- Fixed bugs in the game simulator that caused inconsistent test results
- Removed obsolete test visualization tool (bin/visualize_test.rb)

## Testing
All tests pass successfully with the new test runner. The infrastructure has been tested with various configurations and edge cases to ensure reliability.

## Usage
```bash
# Run all tests
bin/run_tests

# Run tests with verbose output
bin/run_tests -v

# Run tests in fast mode
bin/run_tests -f

# Skip specific test types
bin/run_tests --skip-rspec
bin/run_tests --skip-game
```

This PR closes #XXX (reference any relevant issues)