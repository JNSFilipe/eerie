# Meow Vim Fork Cleanup Refactor Design

## Goal

Refactor the current Vim-style Meow fork to remove leftover upstream or
compatibility code that no longer serves the shipped workflow, while
preserving the behavior covered by the current README, AGENTS notes,
and ERT suite.

This is an internal cleanup effort, not a feature redesign.

## Scope

In scope:

- Remove internal code paths that are no longer part of the canonical
  workflow shipped by this fork.
- Simplify and deduplicate live code, especially in
  `meow-command.el`.
- Keep the current modal model, keymaps, visible-jump behavior,
  operator flow, visual modes, jump history, multi-edit behavior, and
  multicursor behavior intact.
- Strengthen tests where cleanup risk is high.

Out of scope:

- Redesigning the user-facing workflow.
- Renaming the public `meow-*` surface.
- Adding new editor features beyond bug fixes uncovered during
  refactor.
- Rewriting upstream `.org` docs in this cleanup effort.

## Behavioral Contract

The behavioral contract for this refactor is defined by:

- `README.md`
- `AGENTS.md`
- `.plan/PLAN.md`
- `tests/meow-vim-tests.el`

If cleanup reveals ambiguity, the tests and documented shipped workflow
win over legacy upstream behavior.

## Live Surface To Preserve

The refactor must preserve:

- normal, visual, insert, multicursor, and multicursor-visual states
- shipped normal/visual keymaps and current Vim-style defaults
- operator-pending behavior currently implemented in the fork
- visible-jump loops for `f`, `w`, and `V`
- window-local jump history and command registration
- block visual behavior, including `d`, `c`, `I`, and `A`
- canonical multicursor workflow:
  - normal `m`
  - visual `m`
  - multicursor `.` / `,` / `-`
  - multicursor promotion with `v`
  - replay-backed insert/change flows

The refactor may remove internal functions that are not part of the
shipped workflow, even if they were once reachable from older Meow or
earlier fork iterations.

## Cleanup Strategy

### 1. Reachability Audit

Build a reachability map from:

- active state keymaps
- state transitions
- pre-command and post-command hooks
- insert-exit and replay paths
- public helpers documented by the fork
- helpers exercised by the ERT suite

Classify internal code into:

- Keep: directly or indirectly required by the shipped workflow
- Refactor: live but duplicated, overly stateful, or poorly bounded
- Delete: dead, superseded, or reachable only through non-canonical
  compatibility paths

### 2. Dead-Path Removal

Delete clearly dead internal helpers, compatibility bridges, stale
variables, and obsolete comments/docstrings in small slices.

Priority for deletion:

- superseded internal multicursor and multiedit entry paths
- compatibility dispatchers kept only for older, non-canonical flows
- dead helper chains referenced only by other dead helpers
- stale upstream-oriented comments that misdescribe the fork

### 3. Live-Code Consolidation

Refactor but keep live code where the fork currently has duplication:

- visual entry and exit routing
- replay setup and replay target handling
- multiedit target management
- multicursor snapshot and overlay restoration
- block visual replay targeting

The preferred technique is to extract smaller internal helpers and
converge overlapping paths, not to introduce new abstractions unless
they clearly reduce duplication and improve readability.

### 4. Documentation Sync

After each verified cleanup slice:

- update `.plan/PLAN.md`
- add/update stage TODO files
- update `README.md` and `AGENTS.md` only if shipped behavior or
  intentional deferrals changed

## Risk Controls

- Treat `tests/meow-vim-tests.el` as the executable contract.
- Add tests before removing uncertain code.
- Remove code in small slices with full verification after each slice.
- Avoid renaming public commands unless they are proven internal and
  dead.
- Prefer extracting helpers over moving large chunks of logic across
  files in one pass.
- If a helper looks dead but may still be involved in state/hook
  behavior, audit references and control flow before deletion.

## Expected Refactor Targets

High-likelihood refactor areas:

- `meow-command.el` visual-state helpers
- duplicated replay paths across multiedit, multicursor, and block
  visual insert/append
- multicursor and multiedit state cleanup/transition helpers
- internal compatibility bridges left over from earlier multicursor
  designs

High-likelihood keep areas:

- `meow-keymap.el` shipped bindings
- `meow-core.el` state plumbing that is still actively used
- `meow-var.el` live state variables and user-facing customization
- `meow-thing.el` text-object behavior currently used by operators and
  visual retargeting

## Execution Stages

1. Audit live entry points and add defensive tests where needed.
2. Remove clearly dead compatibility/internal paths.
3. Consolidate live duplicated helpers without changing behavior.
4. Sync docs and stage trackers to the resulting codebase.

## Verification

At the end of each cleanup stage:

- `emacs -Q --batch -L . -l meow.el`
- `emacs -Q --batch -L . -L tests -l tests/meow-vim-tests.el -f ert-run-tests-batch-and-exit`

The refactor is only complete when:

- the full shipped behavior still passes
- dead compatibility paths are removed
- the remaining live code is easier to trace from keymap entry point to
  concrete behavior
- duplication in the visual/multiedit/multicursor area is materially
  reduced

## Deferred Work

This cleanup does not attempt to solve already-deferred feature work
such as:

- operator counts
- search-repeat motions inside operators
- full multi-target yank
- linewise or blockwise multicursor seed matching
- broader arbitrary interactive multicursor flows beyond the current
  mirrored normal/visual replay coverage
- full Vim-style block `c` semantics
- rewriting legacy upstream `.org` documentation
