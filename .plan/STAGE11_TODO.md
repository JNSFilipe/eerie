# Stage 11 TODO

## Goal

Fix the remaining linewise visual regressions reported after Stage 10.

## Scope

- [x] Replace the direction-sensitive `V` movement path with an anchor-based
  linewise selection model
- [x] Ensure `V` starts on exactly the current line
- [x] Ensure `V j k` and `V k j` keep the original line selected when they
  return to the anchor
- [x] Preserve the corrected blockwise `C-v` column behavior from Stage 10

## Verification

- [x] Add ERT coverage for `V` starting on a single line
- [x] Add ERT coverage for `V j k` keeping the anchor line selected
- [x] Add ERT coverage for `V k j` keeping `j` / `k` aligned with buffer
  direction
- [x] Re-run the full existing ERT suite and batch load smoke test
