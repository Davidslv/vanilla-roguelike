# Contributing to Vanilla Roguelike

Thanks for helping. Vanilla is maintained by one person in spare time, so this page is mostly about making your pull request easy to review and merge.

## Before you start

- **Bug fix or small improvement:** open a pull request directly. Link the issue if there is one.
- **New feature or larger change:** open a [feature request](https://github.com/Davidslv/vanilla-roguelike/issues/new?template=feature_request.yml) first and wait for a reply. Big features get a written proposal in [`docs/proposals/`](docs/proposals/) (numbered, e.g. `013_<name>_proposal.md`) before code. See [012](docs/proposals/012_end_to_end_playability_testing_proposal.md) for the shape.
- **Question:** see [SUPPORT.md](SUPPORT.md).

This saves you writing code for a change that does not fit the game or the book it accompanies.

## Set up

Follow [docs/getting-started.md](docs/getting-started.md). In short:

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

Both commands must pass on `main` before you start. If they don't, open an issue.

## Make the change

- Read [docs/architecture.md](docs/architecture.md), especially "Where This Design Strains".
- Follow the ECS split: components hold data, systems hold logic. Recipes are in [docs/how-to.md](docs/how-to.md).
- Follow [docs/coding-practices.md](docs/coding-practices.md) for method order.
- Write the spec first where you can. A bug fix should come with a spec that fails without the fix.
- Specs mirror `lib/` under `spec/lib/`. Whole-game behaviour goes in `spec/integration/`, driven through `spec/support/headless_game.rb`.
- If you changed game behaviour on purpose, re-record the replay tapes in the same PR and check the diff ([how-to](docs/how-to.md#re-record-replay-tapes)).
- Update the docs your change makes wrong: README key table, `docs/`, `AGENTS.md`.

## The gates

CI runs on every push and pull request. Both must be green:

| Gate | Command |
|---|---|
| Tests (Ubuntu and macOS) | `bundle exec rspec` |
| Lint | `bundle exec rubocop` |

Don't add entries to `.rubocop_todo.yml` to get past the lint gate. Fix the offence, or explain in the PR why the cop is wrong here.

## Commits and pull requests

- Branch from `main`. Name the branch after the work, e.g. `fix/141-keyboard-handler-cleanup`.
- Commit subjects are short imperative sentences: `Fix NoMethodError on quit`, `Add replay regression tapes`.
- The PR description says what changed and why, how you tested it, and `Closes #N` if it fixes an issue. The template prompts for this.
- PRs are squash-merged, so the PR title becomes the commit on `main`.

## Review

The maintainer reviews every PR. There is no review SLA. If a PR has had no reply for two weeks, a comment to bump it is welcome.

## License

By contributing, you agree that your contribution is licensed under the [MIT License](LICENSE).
