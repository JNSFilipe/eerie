# Stage 46 TODO

## Goal

Consolidate duplicated live helpers in the visual, replay, multiedit,
and multicursor paths without changing shipped behavior.

## Tasks

- [x] Consolidate replay-target handling across multiedit, multicursor,
  and block visual insert flows so the insert replay path shares one
  target-selection model
- [x] Consolidate the duplicated visual exit and state-reset helpers
  that currently split normal, visual, multicursor, and block teardown
- [x] Remove redundant allowlists and overlapping compatibility
  branches only after the shared helpers cover the live flows
- [x] Re-run the focused replay and teardown regressions after each
  consolidation slice
- [x] Update `README.org`, `AGENTS.md`, and `.plan` summaries to match
  the final code
- [x] Re-run the batch load smoke test
- [x] Re-run the full ERT suite

## Completed

- Added explicit teardown regressions for block-visual exit and
  multicursor-visual exit without an active builder, then kept those
  behaviors green through the consolidation pass.
- Extracted a shared visual cleanup helper for the live exit paths so
  block replay startup, visual exit, multicursor visual exit,
  multicursor cancel, and multiedit clear all use the same rectangle
  and region teardown path.
- Reviewed `README.org` and `AGENTS.md`; no user-facing or scope text
  changed in this stage because the consolidation was internal-only.
