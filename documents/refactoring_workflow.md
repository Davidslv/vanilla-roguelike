# Refactoring Workflow

This document outlines the development workflow for the Vanilla roguelike game refactoring project, including branch management, commit guidelines, testing procedures, and code review processes.

## Repository Management

### Branch Structure

We'll use the following branch structure for the refactoring process:

- `master`: Stable, production-ready code
- `develop`: Integration branch for development work
- `feature/phase-X-*`: Feature branches for each phase of refactoring
- `fix/*`: Branches for bug fixes

### Branch Naming Conventions

- Phase branches: `feature/phase-0-setup`, `feature/phase-1-components`, etc.
- Feature branches: `feature/phase-1-position-component`, `feature/phase-2-entity-factory`, etc.
- Fix branches: `fix/message-system-params`, `fix/render-system-crash`, etc.

### Commit Guidelines

1. **Atomic Commits**: Each commit should represent a single logical change
2. **Descriptive Messages**: Use clear, descriptive commit messages
3. **Reference Issues**: Include issue numbers in commit messages when applicable

Format:
```
[Phase-X] Brief description of the change

More detailed explanation if needed.

Refs #issue-number
```

Example:
```
[Phase-1] Add set_position method to PositionComponent

- Added proper encapsulation with set_position method
- Removed direct attr_accessor
- Updated tests

Refs #42
```

## Development Workflow

### 1. Task Selection

1. Choose a task from the current phase of the refactoring plan
2. Create an issue in the issue tracker with detailed description
3. Assign the issue to yourself

### 2. Branch Creation

1. Create a new branch from `develop` using the naming convention:
   ```
   git checkout develop
   git pull
   git checkout -b feature/phase-1-position-component
   ```

### 3. Implementation

1. Implement the changes according to the ECS standards
2. Add or update tests for the changes
3. Ensure all existing tests still pass
4. Commit changes with descriptive messages

### 4. Code Review

1. Push your branch to the remote repository
2. Create a pull request (PR) to the `develop` branch
3. Assign reviewers to the PR
4. Address any feedback from the code review

### 5. Integration

1. Once approved, merge the PR into `develop`
2. Delete the feature branch after successful merge

## Testing Procedures

### Running Tests

Run tests before committing changes:

```bash
bundle exec rspec
```

Run specific tests for the component or system you're working on:

```bash
bundle exec rspec spec/lib/vanilla/components/position_component_spec.rb
```

### Writing Tests

1. Update or create unit tests for components and systems
2. Update integration tests as needed
3. Add regression tests for any bugs discovered

### Test Coverage

We aim to maintain or improve the current test coverage (84.65%). Use SimpleCov to check coverage:

```bash
COVERAGE=true bundle exec rspec
```

## Code Review Process

### Review Checklist

Reviewers should check for:

1. **Adherence to ECS Standards**
   - Components contain only data
   - Systems contain all behavior
   - No direct system-to-system calls
   - Proper event-based communication

2. **Code Quality**
   - Follows Ruby style guidelines
   - Well-documented with clear comments
   - No code smells or anti-patterns

3. **Test Coverage**
   - All new/modified code is covered by tests
   - Edge cases are addressed
   - No regressions in existing functionality

4. **Architecture Integrity**
   - Changes align with the overall refactoring plan
   - No shortcuts that violate architectural principles

### Review Comments

- Be specific and constructive in review comments
- Suggest alternatives when pointing out issues
- Use a collaborative and respectful tone

## Phase Completion

At the end of each phase:

1. Create a summary of what was accomplished
2. Update the refactoring plan with any changes or newly discovered issues
3. Plan the next phase based on what was learned

## Documentation

As part of the refactoring process, update or create:

1. Class and method documentation
2. Architectural documentation
3. Usage examples for components and systems
4. API references for public interfaces

## Tools and Resources

### Code Analysis

- RuboCop for Ruby style checking
- SimpleCov for test coverage
- YARD for documentation generation

### Continuous Integration

- Run tests automatically on PRs
- Enforce code style guidelines
- Check test coverage thresholds

## Conclusion

Following this workflow will help ensure a smooth refactoring process while maintaining code quality and functionality. The structured approach allows for incremental improvements and quick identification of any issues that arise during the refactoring.