# Stage 45 TODO

## Goal

Prune the remaining confirmed dead upstream surface without touching
the Stage 43 keep list.

## Decision Record

- Stage 43 classified `meow-find-ref`, clipboard, comment, page,
  slurp, sexp, wrap, open, and replace helpers as keep for now.
- `meow-visual-search-next-or-multicursor` is not a Stage 45 target;
  Stage 44 owns that deletion.
- Stage 45 is only expected to prune any other confirmed dead upstream
  surface that remains after Stage 44, and to delete anything else only
  if the prune pass proves it is still unreachable.
- Stage 45 may still remove stale references from `meow-var.el`,
  `meow-beacon.el`, and `meow-tutor.el`, but only for helpers this pass
  confirms are dead.

## Tasks

- [x] Remove any helpers this pass proves unreachable, excluding
  `meow-visual-search-next-or-multicursor`
- [x] Remove the matching stale references from `meow-var.el`,
  `meow-beacon.el`, and `meow-tutor.el` for the helpers actually
  deleted in this stage
- [x] Add or adjust tests for any helper that turns out to still be
  live after the first pruning pass
- [x] Re-run the focused replay, operator, and jump regressions after
  each prune
- [x] Re-run the batch load smoke test
- [x] Re-run the full ERT suite

## Completed

- Removed the unreachable `meow-open-above`, `meow-open-above-visual`,
  `meow-open-below`, and `meow-open-below-visual` command family from
  `meow-command.el`.
- Removed the dead `meow-select-on-open` custom, the stale
  `meow-open-above` and `meow-open-below` indicator labels, and the
  stale beacon-state remaps that only referenced those deleted
  commands.
- Removed the obsolete tutor text that still documented the deleted
  open-above and open-below commands.
- Added a regression that asserts the deleted commands, their
  indicator entries, and their beacon remaps stay gone.
