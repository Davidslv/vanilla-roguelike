# Governance

## Model

Vanilla has one maintainer, [David Silva](https://github.com/Davidslv), who makes the final call on every change. This is a benevolent-dictator model. It fits a project this size and keeps the code in step with the book it accompanies.

## How decisions are made

- **Small changes** (bug fixes, docs, tests, refactors with no behaviour change): decided in the pull request.
- **Features and design changes:** discussed in an issue first. Larger ones are written up as a numbered proposal in [`docs/proposals/`](docs/proposals/) and accepted or declined there. The proposal records the reasoning so later contributors can see why.
- **What the game should be:** Vanilla stays a small, readable, plain-Ruby roguelike that teaches ECS. Changes that make the code much harder to follow are likely to be declined, even if they add features.

## Changing this model

If regular contributors appear, the plan is to add maintainers (see [MAINTAINERS.md](MAINTAINERS.md)) and move to decision by maintainer consensus. Any change to this document is made by pull request.
