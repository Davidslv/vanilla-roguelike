# Contributing to Vanilla Roguelike

Welcome to **Vanilla Roguelike**! We're thrilled you're interested in contributing to our open-source project. This document outlines how to contribute effectively, ensuring a smooth and collaborative experience for everyone. Whether you're fixing bugs, adding features, or improving documentation, your contributions help make Vanilla Roguelike better for the community.

## Table of Contents
- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Contribution Process](#contribution-process)
  - [Discussing New Features](#discussing-new-features)
  - [Implementation Guidelines](#implementation-guidelines)
  - [Submitting Your Contribution](#submitting-your-contribution)
- [Types of Contributions](#types-of-contributions)
  - [Bug Reports](#bug-reports)
  - [Feature Requests](#feature-requests)
  - [Code Contributions](#code-contributions)
  - [Documentation](#documentation)
- [Testing](#testing)
- [Review Process](#review-process)
- [Questions?](#questions)
- [Recognition](#recognition)

## Code of Conduct

We are committed to fostering an inclusive and respectful community. By contributing, you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md). Please read it to understand the expectations for behavior in our community.

## Getting Started

1. **Fork the Repository**: Fork the this repository to your GitHub account.
2. **Clone Your Fork**:
   ```bash
   git clone https://github.com/your-username/vanilla-roguelike.git
   cd vanilla-roguelike
   ```
3. **Set Up the Environment**: Follow the setup instructions in the [README.md](README.md) to install dependencies and configure your development environment.
4. **Explore the Project**: Review the project structure, existing issues, and documentation in the `docs/` folder to familiarize yourself with the codebase.

## Contribution Process

### Discussing New Features

To ensure contributions align with the project's vision, we require discussion before implementing new features:

1. **Create an Issue**:
   - Open a GitHub issue with a clear title (e.g., `[Feature] Add procedural dungeon generation`).
   - Use the provided issue template for feature requests.
   - Describe the feature, its purpose, and its benefits to the game.
   - Include a high-level implementation plan, detailing:
     - Affected files or components.
     - Potential impact on existing functionality.
     - Any dependencies or risks.
   - (Optional) Include a [Mermaid diagram](https://mermaid-js.github.io/) for complex features to illustrate the design. Example:
     ```mermaid
     graph TD
       A[Player Input] --> B[Game Logic]
       B --> C[Render Map]
       C --> D[Display Output]
     ```
2. **Engage in Discussion**:
   - Allow time for maintainers and the community to review and provide feedback.
   - Respond to comments and refine your proposal as needed.
3. **Get Approval**:
   - Wait for maintainer approval before starting implementation to avoid wasted effort.

This process ensures features are well-planned, align with the project's goals, and benefit from community input.

### Implementation Guidelines

Once your feature is approved or you're working on a bug fix:

1. **Create a Branch**:
   - Use a descriptive branch name, e.g., `feature/add-inventory-system` or `fix/player-movement-bug`.
   ```bash
   git checkout -b feature/your-feature-name
   ```
2. **Follow Coding Standards**:
   - Adhere to the project's style guide (see `.rubocop.yml`).
   - Run RuboCop to ensure compliance:
     ```bash
     bundle exec rubocop
     ```
   - Fix any linting issues before submitting.
3. **Write Tests**:
   - Add tests for new functionality or bug fixes using the project's testing framework (e.g., RSpec).
   - Ensure tests cover both happy paths and edge cases.
   - Run tests locally:
     ```bash
     bundle exec rspec
     ```
4. **Update Documentation**:
   - Update `README.md` for user-facing changes.
   - Add or update code comments for complex logic.
   - Update architecture docs in `docs/` for structural changes.

### Submitting Your Contribution

1. **Commit Your Changes**:
   - Use clear, concise commit messages following the [Conventional Commits](https://www.conventionalcommits.org/) format, e.g.:
     ```
     feat: add inventory system with item stacking
     fix: resolve player movement collision bug
     ```
   - Reference the related issue (e.g., `Addresses #123`).
2. **Create a Pull Request**:
   - Open a pull request (PR) against the `main` branch.
   - Use a clear title (e.g., `Add inventory system (#123)`).
   - Include in the PR description:
     - A summary of changes.
     - Reference to the original issue (e.g., `Closes #123`).
     - Any breaking changes or deprecations.
     - Screenshots or videos for UI/gameplay changes (if applicable).
3. **Address Feedback**:
   - Respond to reviewer comments and make requested changes.
   - Push updates to the same branch to keep the PR current.

## Types of Contributions

### Bug Reports

Help us improve by reporting bugs. When submitting a bug report, include:
- A clear description of the issue.
- Steps to reproduce, including the seed number for random generation issues.
- Expected vs. actual behavior.
- Ruby version, operating system, and relevant dependencies.
- Error messages, logs, or screenshots, if applicable.

Use the bug report issue template for consistency.

### Feature Requests

Propose new features by:
- Clearly describing the feature and its use case.
- Explaining how it benefits players or developers.
- Considering impacts on existing functionality.
- Providing a rough implementation plan (see [Discussing New Features](#discussing-new-features)).

### Code Contributions

We welcome:
- Bug fixes.
- New features (after discussion and approval).
- Performance optimizations.
- Refactoring for improved readability or maintainability.
- Test suite enhancements.

### Documentation

Documentation is critical for usability and maintainability:
- Update `README.md` for installation, usage, or feature changes.
- Improve code comments for clarity.
- Enhance architecture or design docs in `docs/`.
- Fix typos or outdated information.

## Testing

- Write tests for all new features and bug fixes.
- Aim for high test coverage, focusing on critical paths.
- Use descriptive test names
- Test edge cases and error conditions.
- Ensure all tests pass before submitting a PR:
  ```bash
  bundle exec rspec
  ```

## Review Process

All pull requests are reviewed for:
- Code quality and adherence to style guidelines.
- Test coverage and correctness.
- Documentation completeness.
- Alignment with project goals.
- Potential performance or compatibility issues.

Currently this project is a team of 1, I will aim to review PRs as promptly as possible.

## Questions?

If you’re unsure about anything:
- Check existing [issues](https://github.com/davidslv/vanilla-roguelike/issues) or [discussions](https://github.com/davidslv/vanilla-roguelike/discussions).
- Open a new issue with your question.
- Review documentation in the `docs/` folder.
- Review closed issues if possible.

You can also reach out via GitHub Discussions for general inquiries or ideas.

## Recognition

We value every contribution! Contributors are recognized in the `CONTRIBUTORS.md` file.

Thank you for helping make Vanilla Roguelike an amazing roguelike experience!

---

By following these guidelines, you help ensure that contributions are high-quality, collaborative, and aligned with the vision of Vanilla Roguelike. Let’s build an epic ruby game together!