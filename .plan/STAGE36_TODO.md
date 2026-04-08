# Stage 36 TODO

## Goal

Replace the old visual-only entry point with a dedicated
`multicursor-mark` mode entered from normal `m`, and keep a persistent
multicursor cheat sheet visible while that mode is active.

## Tasks

- [x] Reuse the existing multicursor normal and visual states as the
  canonical user-facing mode
- [x] Bind normal `m` to enter the canonical multicursor session
- [x] Keep seed creation inside the new mode using the existing
  selection grammar
- [x] Add a persistent keypad-style multicursor cheat sheet and clear it
  on mode exit
- [x] Make `ESC` cancel the whole session and return to normal
- [x] Add failing and then passing ERT coverage for normal `m` entry,
  persistent menu display, and `ESC` teardown
- [x] Update README, AGENTS, and `.plan/PLAN.md`
- [x] Re-run the batch load smoke test
- [x] Re-run the full ERT suite
