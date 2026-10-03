# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Vanilla has no tagged releases yet. Changes before this file was restarted are in the git history and merged pull requests.

## [Unreleased]

### Added

- A real turn: `World#end_turn` counts each player action that takes time and emits `turn_ended` (#160). The message log's turn number and effect durations now use it, so menus, `f` and unknown keys no longer advance it.
- Game over: when the player dies the game shows the cause, the floor reached and the seed, waits for a key, and exits (#159). New `player_died` event.
- Community files: `SUPPORT.md`, `GOVERNANCE.md`, `MAINTAINERS.md`, `CITATION.cff`, `.editorconfig`.
- GitHub issue forms (bug, feature, question), pull request template, `CODEOWNERS`, Dependabot config.
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

### Fixed

- The custom `ECS/ComponentBehavior` cop crashed on class methods, so RuboCop exited 1 while reporting no offences.
- `scripts/generate_events_md.rb` works from any directory.

### Removed

- The book manuscript, articles, text diagrams and PDF build tooling. The book is a separate work and lives elsewhere.
- Stale files: reddit reply drafts, `BREAKPOINT.md`, empty `CONTRIBUTORS.md`, three manual test scripts covered by specs.
