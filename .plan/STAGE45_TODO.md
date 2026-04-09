# Stage 45 TODO

## Goal

Prune unreachable upstream command surface and stale internal
references that are no longer part of the Vim fork.

## Tasks

- [ ] Remove unreachable upstream command definitions confirmed by the
  audit, including dead `find-ref`, clipboard, comment, page, slurp,
  sexp, wrap, open, and replace helpers if they are still unshipped
- [ ] Remove the matching stale references from `meow-var.el`,
  `meow-beacon.el`, and `meow-tutor.el`
- [ ] Add or adjust tests for any dependency that turns out to still be
  live after the first pruning pass
- [ ] Re-run the focused replay, operator, and jump regressions after
  each prune
- [ ] Re-run the batch load smoke test
- [ ] Re-run the full ERT suite
