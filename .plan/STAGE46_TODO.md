# Stage 46 TODO

## Goal

Consolidate duplicated live helpers in the visual, replay, multiedit,
and multicursor paths without changing shipped behavior.

## Tasks

- [ ] Consolidate replay-target handling across multiedit, multicursor,
  and block visual insert flows
- [ ] Consolidate duplicated visual exit and state-reset helpers
- [ ] Remove redundant allowlists and overlapping compatibility branches
- [ ] Re-run focused regressions after each consolidation slice
- [ ] Update docs and `.plan` summaries to match the final code
- [ ] Re-run the batch load smoke test
- [ ] Re-run the full ERT suite
