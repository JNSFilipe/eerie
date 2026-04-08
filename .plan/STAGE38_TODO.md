# Stage 38 TODO

## Goal

Make `multicursor-mark` the single canonical multicursor execution flow,
with mirrored normal and visual commands acting across the full target
set.

## Tasks

- [x] Remove the old extra spawn step from the user-facing flow and keep replay inside the
  canonical multicursor mode
- [x] Keep selection-entry and visual-retargeting flows such as `v`,
  `V`, `C-v`, `vi(`, and `va"` multicursor-aware
- [x] Keep visible-jump flows such as `f<char>1` multicursor-aware
- [x] Make edit commands such as `d`, `c`, `i`, `a`, `I`, and `A` act
  across every active target
- [x] Keep point, mark, and selection metadata stable across replayed
  commands
- [x] Add ERT coverage for mirrored normal and visual replay after the
  redesign
- [x] Update README, AGENTS, and `.plan/PLAN.md`
- [x] Re-run the batch load smoke test
- [x] Re-run the full ERT suite
