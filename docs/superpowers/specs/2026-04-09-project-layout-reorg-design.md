# Eerie Project Layout Reorganization Design

## Goal

Clean up the repository layout so the shipped package code no longer
lives at the repo root, while preserving the current `eerie` package
behavior and keeping the maintained docs and tests easy to find.

After this reorganization:

- shipped Emacs Lisp lives under `lisp/`
- canonical tests stay under `tests/`
- canonical docs stay at the root and under `docs/superpowers/`
- stale legacy `.org` docs are removed instead of archived

## Chosen Approach

Use a medium-scope repository reorganization:

- move all shipped `eerie*.el` files into `lisp/`
- update packaging, load paths, tests, and documented commands to load
  from `lisp/`
- delete the legacy root `.org` documentation files that no longer
  describe the shipped fork
- delete tracked editor backup files and keep backup junk out of the
  tree

This is intentionally a filesystem and packaging cleanup, not a
behavioral redesign.

## Approaches Considered

### 1. Conservative root cleanup only

Keep the shipped Lisp files at the root and only move or delete docs.

Pros:

- lowest packaging risk
- smallest diff

Cons:

- leaves the main source graph mixed into the repo root
- does not solve the core structural complaint

### 2. Recommended: `lisp/` source split plus legacy-doc deletion

Move shipped Elisp into `lisp/`, keep tests and canonical docs in place,
and delete stale legacy `.org` docs.

Pros:

- matches normal Emacs package conventions
- significantly reduces root clutter
- keeps canonical user and contributor docs easy to discover

Cons:

- requires coordinated `Eask`, README, and test-command updates

### 3. Broader docs-and-internals restructure

Do option 2 plus reorganize `.plan/`, `docs/superpowers/`, and other
internal material.

Pros:

- cleanest possible tree

Cons:

- more churn than needed for the current goal
- risks destabilizing paths that are already part of the repo workflow

## Target Structure

### Root

Keep these at the repo root:

- `README.md`
- `AGENTS.md`
- `CHANGELOG.md`
- `Eask`
- `LICENSE`
- `.plan/`
- `docs/superpowers/`
- `tests/`
- logo assets such as `eerie.png`

### Source Directory

Create `lisp/` and move all shipped Elisp there:

- `lisp/eerie.el`
- `lisp/eerie-*.el`

This includes the entry point and every shipped module.

### Tests

Keep these in `tests/`:

- `tests/eerie-vim-tests.el`
- `tests/eerie-interactive-demo.el`

Only their load-path assumptions change.

### Deleted Material

Delete the stale root `.org` docs:

- `README.org`
- `COMMANDS.org`
- `CUSTOMIZATIONS.org`
- `EXPLANATION.org`
- `FAQ.org`
- `GET_STARTED.org`
- `KEYBINDING_COLEMAK.org`
- `KEYBINDING_DVORAK.org`
- `KEYBINDING_DVP.org`
- `KEYBINDING_QWERTY.org`
- `KEYBINDING_QWERTZ.org`
- `TUTORIAL.org`
- `VIM_COMPARISON.org`

Also delete tracked editor backup files such as:

- `#FAQ.org#`
- `tests/#meow-interactive-demo.el#`
- `tests/#meow-vim-tests.el#`

## Packaging And Command Changes

### Eask

`Eask` must be updated so the package still builds and tests from the
new layout:

- `package-file` becomes `lisp/eerie.el`
- `files` targets `lisp/eerie*.el` and `lisp/eerie.el`
- the test script uses `-L lisp -L tests`

### Verification Commands

The canonical smoke and test commands become:

```bash
emacs -Q --batch -L lisp -l lisp/eerie.el
emacs -Q --batch -L lisp -L tests -l tests/eerie-vim-tests.el -f ert-run-tests-batch-and-exit
```

### Documentation

`README.md`, `AGENTS.md`, and `.plan/*` must be updated to use the new
`lisp/` load-path examples.

## Explicit Non-Goals

- no behavioral changes to the `eerie` modal workflow
- no further redesign of tests, plans, or `docs/superpowers/`
- no archival `docs/legacy/` folder for stale upstream `.org` docs
- no renaming of the `tests/` directory

## Risks And Controls

### Risk: package load breaks after moving files

Control:

- move files with `git mv`
- update `Eask` and load-path commands in the same change
- run the smoke test immediately after the move

### Risk: tests still assume root-level Elisp files

Control:

- update the test command to use `-L lisp`
- keep test file paths unchanged so only the load path moves
- run the full ERT suite after the reorg

### Risk: stale references to deleted legacy docs remain

Control:

- audit canonical docs and config for references before deleting the
  `.org` files
- only keep maintained docs that describe the shipped fork

### Risk: editor backup files return to the repo

Control:

- delete tracked backup artifacts during the same cleanup pass
- rely on the existing `.gitignore` backup patterns, extending them only
  if the audit shows gaps

## Success Criteria

The reorganization is complete when all of the following are true:

- all shipped `eerie*.el` files live under `lisp/`
- the package loads with
  `emacs -Q --batch -L lisp -l lisp/eerie.el`
- the full ERT suite passes with
  `emacs -Q --batch -L lisp -L tests -l tests/eerie-vim-tests.el -f ert-run-tests-batch-and-exit`
- the canonical docs and tracker files point at the `lisp/` layout
- the stale legacy root `.org` docs are gone
- tracked editor backup files are gone
- the repo root is materially cleaner and contains only actively used
  project-facing files
