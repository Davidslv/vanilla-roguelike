# Vanilla Game Testing Guide

This document provides information about testing the Vanilla game project, including the available testing mechanisms and how to use them.

## Test Runner

A comprehensive test runner script is provided to execute all testing mechanisms with a single command. This ensures all game mechanics are working properly.

### Basic Usage

```bash
# Run all tests
bin/run_tests

# Run tests with verbose output
bin/run_tests -v

# Run tests in fast mode (reduces test duration)
bin/run_tests -f

# Use a specific seed for reproducibility
bin/run_tests -s 12345

# Skip specific test types
bin/run_tests --skip-rspec
bin/run_tests --skip-game

# Specify output directory for test results
bin/run_tests -o ./my_test_results
```

### Output and Results

The test runner will:

1. Create timestamped log files for each test category
2. Generate a summary report with pass/fail information
3. Exit with status code 0 if all tests pass, 1 if any fail

Results are stored in the `test_results` directory by default, with each test run getting its own set of log files with timestamps.

## Available Test Mechanisms

### 1. RSpec Tests

Unit tests and component tests using RSpec framework.

```bash
# Run directly (not recommended, use run_tests instead)
bundle exec rspec
```

### 2. Game Simulator Tests

The GameSimulator allows automated game testing without manual input. It includes:

#### Movement Tests

Tests basic player movement in all four directions.

```bash
# Run directly (not recommended, use run_tests instead)
bin/test_game
```

#### Stairs Tests

Tests level transitions using stairs.

```bash
# Run directly (not recommended, use run_tests instead)
bin/test_game --test-stairs
```

## Troubleshooting

### Common Issues with MoveCommand

If you encounter errors related to MoveCommand, ensure proper parameter order:

```ruby
# CORRECT: MoveCommand.new(entity, direction, grid)
MoveCommand.new(player, :north, grid)

# WRONG: This will cause an error
MoveCommand.new(player, grid, :north)
```

For more details, see the [Commands README](../lib/vanilla/commands/README.md).

### Debugging Test Failures

1. Check the test logs in the `test_results` directory
2. Run the specific test with verbose output (`-v` flag)
3. Use a specific seed to reproduce the issue

## Extending Tests

### Adding New Game Simulator Tests

To add a new test type to the game simulator:

1. Add an option to `bin/test_game`
2. Implement the test action in the case statement
3. Update `bin/run_tests` to include the new test type

### Adding New Test Types

If you create entirely new testing mechanisms:

1. Implement your test
2. Add an option to skip it in `bin/run_tests`
3. Add a section to run the test in `bin/run_tests`
4. Update this documentation

## Continuous Integration

When setting up CI, use the `bin/run_tests` script as your primary test command:

```yaml
# Example GitHub Actions workflow step
- name: Run tests
  run: bin/run_tests
```

This will ensure all tests are run and the build fails if any test fails.