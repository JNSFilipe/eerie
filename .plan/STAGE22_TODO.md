# Stage 22 TODO

## Goal

Make reverse visual `f` refresh its numbered candidates correctly after
each jump within the same hint loop.

## Scope

- [x] Recompute the visual-cursor exclusion range on every visual `f`
  loop iteration
- [x] Fix stale numbering after `f<char> ; 1` within a single visual `f`
  invocation
- [x] Preserve the fix for both plain visual and `w`-started selections

## Verification

- [x] Add ERT coverage for same-loop reverse visual `f` on a plain visual
  selection
- [x] Add ERT coverage for same-loop reverse visual `f` on a `w`-started
  selection
- [x] Re-run the full existing ERT suite and batch load smoke test
