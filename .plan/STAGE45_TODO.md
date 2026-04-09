# Stage 45 TODO

## Goal

Prune unreachable upstream command surface and stale internal
references that are no longer part of the Vim fork.

## Tasks

- [ ] Remove unreachable upstream command definitions confirmed by the audit
- [ ] Remove matching dead references from `meow-var.el`,
  `meow-beacon.el`, and `meow-tutor.el`
- [ ] Add or adjust tests for any unexpectedly live dependency
- [ ] Re-run focused replay and operator regressions
- [ ] Re-run the batch load smoke test
- [ ] Re-run the full ERT suite
