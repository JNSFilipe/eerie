# Stage 33 TODO

## Goal

Make multi-cursor normal mode mirror the normal and visual command set
closely enough for selection entry and nested-input commands like
`f<char>1` and `vi(`.

## Tasks

- [x] Replace the old dedicated multi-cursor `f` / `W` override model
  with mirrored multi-cursor normal and visual states
- [x] Preserve per-cursor normal or visual state, active region, and
  visual metadata across replayed commands
- [x] Capture nested `read-key`, `read-char`, and
  `read-from-minibuffer` inputs for supported multi-cursor replay flows
- [x] Add explicit replay coverage for normal visible `f<char>1`
- [x] Add explicit replay coverage for visual text-object flows such as
  `vi(`
- [x] Return multi-cursor visual actions to multi-cursor normal after
  destructive commands finish
- [x] Keep insert replay handoff working after the new command-capture
  layer is added
- [x] Update README, AGENTS, and `.plan/PLAN.md`
- [x] Re-run the batch load smoke test
- [x] Re-run the full ERT suite
