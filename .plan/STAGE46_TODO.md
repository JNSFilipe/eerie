# Stage 46 TODO

## Goal

Consolidate duplicated live helpers in the visual, replay, multiedit,
and multicursor paths without changing shipped behavior.

## Tasks

- [ ] Consolidate replay-target handling across multiedit, multicursor,
  and block visual insert flows so the insert replay path shares one
  target-selection model
- [ ] Consolidate the duplicated visual exit and state-reset helpers
  that currently split normal, visual, multicursor, and block teardown
- [ ] Remove redundant allowlists and overlapping compatibility
  branches only after the shared helpers cover the live flows
- [ ] Re-run the focused replay and teardown regressions after each
  consolidation slice
- [ ] Update `README.md`, `AGENTS.md`, and `.plan` summaries to match
  the final code
- [ ] Re-run the batch load smoke test
- [ ] Re-run the full ERT suite
