# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Vanilla has no tagged releases yet. Changes before this file was restarted are in the git history and merged pull requests.

## [Unreleased]

### Added

- Community files: `SUPPORT.md`, `GOVERNANCE.md`, `MAINTAINERS.md`, `CITATION.cff`, `.editorconfig`.
- GitHub issue forms, pull request template, `CODEOWNERS`, Dependabot config.
- `docs/getting-started.md` and `docs/how-to.md`; design rationale and known limits in `docs/architecture.md`.
- `AGENTS.md` and `llms.txt`.
- RuboCop as a CI gate.
- Spec for the terminal HUD (seed, level, HP), replacing a manual script.
- Spec that checks doc links and the documented system order.

### Changed

- `documents/` renamed to `docs/`.
- `MIT-LICENSE` renamed to `LICENSE`.
- README rewritten: correct key list and default maze algorithm, links to the docs.
- The game no longer loads `pry` at boot.

### Removed

- The book manuscript, articles, text diagrams and PDF build tooling. The book is a separate work and lives elsewhere.
- Stale files: reddit reply drafts, `BREAKPOINT.md`, empty `CONTRIBUTORS.md`, three manual test scripts covered by specs.
