# Stage 45 TODO

## Goal

Prune the remaining confirmed dead upstream surface without touching
the Stage 43 keep list.

## Decision Record

- Stage 43 classified `meow-find-ref`, clipboard, comment, page,
  slurp, sexp, wrap, open, and replace helpers as keep for now.
- Stage 45 is only expected to prune the remaining confirmed dead
  surface, starting with `meow-visual-search-next-or-multicursor`, and
  to delete anything else only if the prune pass proves it is still
  unreachable.
- Stage 45 may still remove stale references from `meow-var.el`,
  `meow-beacon.el`, and `meow-tutor.el`, but only for helpers this pass
  confirms are dead.

## Tasks

- [ ] Remove `meow-visual-search-next-or-multicursor` and any other
  helpers this pass proves unreachable
- [ ] Remove the matching stale references from `meow-var.el`,
  `meow-beacon.el`, and `meow-tutor.el` for the helpers actually
  deleted in this stage
- [ ] Add or adjust tests for any helper that turns out to still be
  live after the first pruning pass
- [ ] Re-run the focused replay, operator, and jump regressions after
  each prune
- [ ] Re-run the batch load smoke test
- [ ] Re-run the full ERT suite
